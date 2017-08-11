import UIKit
import Foundation

class MainVC: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var shareButtton: UIBarButtonItem!
    @IBOutlet weak var cropButton: UIBarButtonItem!
    @IBOutlet weak var fontButton: UIBarButtonItem!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var selectPhotoLabel: UILabel!
    
    var fontTableView: UITableView!
    var fontNames: [String]!
    var tapGestureRecognizer: UITapGestureRecognizer!
    

    // MARK: - Life Cycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topTextView.delegate = self
        bottomTextView.delegate = self
        topTextView.textContainer.maximumNumberOfLines = 2
        bottomTextView.textContainer.maximumNumberOfLines = 2
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        addTapGestureRecognizerToContainerView()
        
        addPlaceholderAttributedTextToTextViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
        let isImageNil = imageView.image == nil
        selectPhotoLabel.isHidden = !isImageNil
        shareButtton.isEnabled = !isImageNil
        topTextView.isHidden = isImageNil
        bottomTextView.isHidden = isImageNil
        
        subscribeToKeyboardNotifications()

        applyGlobalFont()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        removeAndReplaceToolbarButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeToKeyboardNotifications()
    }

    
    // MARK: - Buttons / Gestures
    
    @IBAction func pickImageTapped(_ sender: UIBarButtonItem) {
        
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        pickerVC.sourceType = .photoLibrary
        present(pickerVC, animated: true, completion: nil)
    }

    @IBAction func cameraButtonTapped(_ sender: UIBarButtonItem) {
       
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        pickerVC.sourceType = .camera
        present(pickerVC, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        
        if let memeImage = captureMemeImage() {
            let activityVC = UIActivityViewController.init(activityItems: [memeImage], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { [unowned self] (activityType, completed, returnedItems, activityError) in
                
                print("We are in the completionWithItemsHandler!!!")
                print("activityType: \(String(describing: activityType))")
                print("completed: \(completed)")
                print("returnedItems: \(String(describing: returnedItems))")
                print("activityError: \(String(describing: activityError))")
                
                if completed {
                    
                    self.saveMeme(memeImage)
                    
                }
                else if let returnedItems = returnedItems {
                    print("returnedItems: \(String(describing: returnedItems))")
                }
                else if let error = activityError {
                    print("non nil errors: \(String(describing: error))")
                }
            }
            
            present(activityVC, animated: true)
        }
        else {
            
            // Handle Error?
            print("Something when wrong in share button")
        }
        
        //TODO: Hot to reset after share?
    }
    
    
    @IBAction func cropButtonTapped(_ sender: UIBarButtonItem) {
    
    }
    
    @IBAction func fontButtonTapped(_ sender: UIBarButtonItem) {

        displayFontTableView()
    }
    
    func addTapGestureRecognizerToContainerView() {
        
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapRecognized(_:)))
        tapGestureRecognizer = tapRecognizer
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func tapRecognized(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        if fontTableView != nil {
            dismissFontTableView()
        }
        else {
            resignWhomeverIsFirstResponder()
        }
    }
    
    func displayFontTableView() {
        
        var fontNamesArray = [String]()
        let  fontFamilies = UIFont.familyNames
        fontFamilies.forEach { (family) in
            fontNamesArray += UIFont.fontNames(forFamilyName: family)
        }
        fontNamesArray.insert("Preferred meme font!", at: 0)
        fontNames = fontNamesArray
        
        let x: CGFloat = 0.0
        let y = view.frame.size.height / 2
        let width = view.frame.size.width
        let height = view.frame.size.height / 2
        let tvFrame = CGRect(x: x, y: view.frame.size.height, width: width, height: height)
        
        let fontTV = UITableView.init(frame: tvFrame)
        fontTV.delegate = self
        fontTV.dataSource = self
        fontTV.register(UITableViewCell.self, forCellReuseIdentifier: "fontCell")
        
        fontTableView = fontTV
        view.addSubview(fontTV)
        
        UIView.animate(withDuration: 0.25) { 
            self.fontTableView.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    func dismissFontTableView() {
        UIView.animate(withDuration: 0.25) { [unowned self] in
            self.fontTableView.frame = CGRect(x: self.fontTableView.frame.origin.x , y: self.view.frame.size.height, width: self.fontTableView.frame.size.height, height: self.fontTableView.frame.size.width)
        }
        
        UIView.animate(withDuration: 0.25, animations: { 
            self.fontTableView.frame = CGRect(x: self.fontTableView.frame.origin.x , y: self.view.frame.size.height, width: self.fontTableView.frame.size.height, height: self.fontTableView.frame.size.width)
        }) { (bool) in
            self.fontTableView.removeFromSuperview()
            self.fontTableView = nil
            print("fontTableView is nil: \(self.fontTableView == nil)")
        }
    }
    
    // MARK: - Font Methods
    
    func applyGlobalFont() {
        
        UILabel.appearance().defaultFontName = kdefaultFontName
        
        // Redraw attributed text already in textViews
        if isPlaceholderAttributedString(topTextView.attributedText) {
            addTopPlaceholderTextWithAttributes(placeholderFontAttributesDict())
        }
        else {
            topTextView.attributedText = NSAttributedString(string: topTextView.attributedText.string, attributes:  memeFontAttributesDict())
        }
        
        if isPlaceholderAttributedString(bottomTextView.attributedText) {
            addTopPlaceholderTextWithAttributes(placeholderFontAttributesDict())
        }
        else {
            bottomTextView.attributedText = NSAttributedString(string: bottomTextView.attributedText.string, attributes:  memeFontAttributesDict())
        }
    
        selectPhotoLabel.font = kDefaultFont
        
        removeAndReplaceToolbarButtons()
    }
    
    func removeAndReplaceToolbarButtons() {
        
        // Required to make UIBarButton titles adopt default font at launch.
        let allButtons = toolbar.items
        toolbar.setItems([], animated: false)
        toolbar.setItems(allButtons, animated: false)
    }
    
    
    // MARK: - Meme Image Methods
    
    func saveMeme(_ image: UIImage?) {
        let topText = isPlaceholderAttributedString(topTextView.attributedText) ? "" : topTextView.attributedText.string
        let bottomText = isPlaceholderAttributedString(bottomTextView.attributedText) ? "" : bottomTextView.attributedText.string
        let originalImage = imageView.image
        let memeImage = image
        
        if let realMemeImage = memeImage, let realOriginalImage = originalImage {

            // TODO: How can we share this in more places?!
            let meme = Meme.init(topText: topText, bottomText: bottomText, originalImage: realOriginalImage, memedImage: realMemeImage)
        }
        else {

            let alertController = UIAlertController(title: "Error: Save failed", message: "There was a problem saving your meme. Please try again.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(okAction)
            present(alertController, animated: true)
            
        }
    }
    
    func captureMemeImage() -> UIImage? {
        
        removePlaceholderText()
        resignWhomeverIsFirstResponder()
        toolbar.isHidden = true
        
        UIGraphicsBeginImageContext(containerView.frame.size)
        containerView.drawHierarchy(in: containerView.frame, afterScreenUpdates: true)
        
        var memeImage: UIImage?
       
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
        
            memeImage = image
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        else {
            
            let alertController = UIAlertController(title: "Error: capture fail", message: "There was a problem saving your meme. Please try again.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { [unowned self] (alert) in
                print("Alert Ok button tapped.")
                self.dismiss(animated: true)
            })
            alertController.addAction(okAction)
            present(alertController, animated: true)
        }
        
        UIGraphicsEndImageContext()
        
        replacePlaceholderText()
        toolbar.isHidden = false
        
        return memeImage
    }
    
    
    // MARK: - Keyboard Methods
    
    func keyboardWillShow(_ notification: NSNotification) {

        animateKeyboardWithNotification(notification)
    }
    
    func keyboardWillDisappear(_ notification: NSNotification) {
        
        if view.frame.origin.y < 0 {
            animateKeyboardWithNotification(notification)
        }
    }
    
    func animateKeyboardWithNotification(_ notification: NSNotification) {
        let newY: CGFloat!
        let newFrame: CGRect!
        
        if notification.name == NSNotification.Name.UIKeyboardWillShow && view.frame.origin.y == 0 && bottomTextView.isFirstResponder {
            newY = view.frame.origin.y - self.getKeyboardHeight(notification: notification)
            newFrame = CGRect(x: 0.0, y: newY , width: view.frame.size.width, height: view.frame.size.height)
        }
        else {
            newY = 0.0
            newFrame = CGRect(x: 0.0, y: newY , width: view.frame.size.width, height: view.frame.size.height)
        }
    
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurve = UIViewAnimationCurve(rawValue: Int(notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber))
            
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(animationCurve!)
        UIView.setAnimationBeginsFromCurrentState(true)
        self.view.frame = newFrame
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat  {
        
        let userInfo = notification.userInfo
        if let keyboardHeight = userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            return keyboardHeight.cgRectValue.height - toolbar.frame.size.height
        }
        
        return 0.0
    }
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    
}


// MARK: - Image Picker Delegate

extension MainVC: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        if let image = info[UIImagePickerControllerEditedImage] {
            imageView.image = (image as! UIImage)
        }
        else if let image = info[UIImagePickerControllerOriginalImage] {
            imageView.image = (image as! UIImage)
        }
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - Navigation Controller Delegate

extension MainVC: UINavigationControllerDelegate {
    
}


// MARK: - Text View Delegate

extension MainVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text == Placeholder.topText || textView.text == Placeholder.bottomText {
            textView.text = ""
        }
        
        let memeFontAttributes = memeFontAttributesDict()
        
        topTextView.typingAttributes = memeFontAttributes
        bottomTextView.typingAttributes = memeFontAttributes
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        if textView.text.characters.count == 0 {
            
            let attributePlaceholderText: NSMutableAttributedString = textView == topTextView ? NSMutableAttributedString.init(string: Placeholder.topText) : NSMutableAttributedString.init(string: Placeholder.bottomText)
            attributePlaceholderText.addAttributes(placeholderFontAttributesDict(), range: NSRange.init(location: 0, length: attributePlaceholderText.length))
            
            textView.attributedText = attributePlaceholderText
        }
        
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        if fontTableView != nil {
            dismissFontTableView()
        }
        
        return true
    }
    
    
    // MARK: Non Delegate TextView Methods
    
    func resignWhomeverIsFirstResponder() {
        
        if topTextView.isFirstResponder {
            topTextView.resignFirstResponder()
        }
        else {
            bottomTextView.resignFirstResponder()
        }
    }
    
    func memeFontAttributesDict() -> [String: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textAttributesDict: [String : Any] = [NSStrokeColorAttributeName: UIColor.black,
                                                  NSFontAttributeName: kDefaultFont ?? UIFont.systemFont(ofSize: 40),
                                                  NSStrokeWidthAttributeName:  -5.0,
                                                  NSForegroundColorAttributeName: UIColor.white,
                                                  NSParagraphStyleAttributeName: paragraphStyle]
        
        return textAttributesDict
    }
    
    func placeholderFontAttributesDict() -> [String: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let placeholderAttributesDict: [String : Any] = [NSForegroundColorAttributeName: UIColor.lightGray,
                                                         NSFontAttributeName: kDefaultFont ?? UIFont.systemFont(ofSize: 40),
                                                         NSParagraphStyleAttributeName: paragraphStyle]
        
        return placeholderAttributesDict
    }
    
    func addPlaceholderAttributedTextToTextViews() {
        
        let placeholderAttributes = placeholderFontAttributesDict()
        
        addTopPlaceholderTextWithAttributes(placeholderAttributes)
        addBottomPlaceholderTextWithAttributes(placeholderAttributes)
    }
    
    func addTopPlaceholderTextWithAttributes(_ attributes: [String: Any]) {
        
        let topAttributedText = NSMutableAttributedString.init(string: Placeholder.topText)
        topAttributedText.addAttributes(attributes, range: NSRange.init(location: 0, length: topAttributedText.length))
        
        topTextView.attributedText = topAttributedText
    }
    
    func addBottomPlaceholderTextWithAttributes(_ attributes: [String: Any]) {
        
        let bottomAttributedText = NSMutableAttributedString.init(string: Placeholder.bottomText)
        bottomAttributedText.addAttributes(attributes, range: NSRange.init(location: 0, length: bottomAttributedText.length))
        
        bottomTextView.attributedText = bottomAttributedText
    }
    
    
    func removePlaceholderText() {
        
        if isPlaceholderAttributedString(topTextView.attributedText) {
            topTextView.attributedText = NSAttributedString.init(string: "")
        }
        
        if isPlaceholderAttributedString(bottomTextView.attributedText) {
            bottomTextView.attributedText = NSAttributedString.init(string: "")
        }
    }
    
    func replacePlaceholderText() {
        
        let placeholderAttributes = placeholderFontAttributesDict()
        
        if topTextView.attributedText.string == "" {
            addTopPlaceholderTextWithAttributes(placeholderAttributes)
        }
        if bottomTextView.attributedText.string == "" {
            addBottomPlaceholderTextWithAttributes(placeholderAttributes)
        }
        
    }
    
    func isPlaceholderAttributedString(_ attributedString: NSAttributedString) -> Bool {
        
        return attributedString.attributes(at: 0, effectiveRange: nil)[NSStrokeWidthAttributeName] != nil ? false : true
    }
    
}

extension MainVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fontCell", for: indexPath)
        
        let pointSize = cell.textLabel?.font.pointSize ?? 17.0

        cell.textLabel?.font = indexPath.row == 0 ? kPreferredFont : UIFont(name: fontNames[indexPath.row], size: pointSize)
        
        cell.textLabel?.text = fontNames[indexPath.row]
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        
        kdefaultFontName = indexPath.row == 0 ? kPreferredFont!.fontName : fontNames[indexPath.row]
        
        dismissFontTableView()
        
        applyGlobalFont()
    }
    
}
