//
//  MemeEditorViewController.swift
//  Meme Me
//
//  Created by Mike Weng on 1/23/16.
//  Copyright © 2016 Weng. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var meme: Meme!
    var memedImage: UIImage!
    
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    var canDismissKeyboard = false
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName : -3.0
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //topTextField.defaultTextAttributes = memeTextAttributes
        
        // add gesture recognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        // set default text style
        setDefaultText()
        
        // text fields delegate
        topTextField.delegate = self
        bottomTextField.delegate = self
        shareButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // check if camera is available, if so enable the button
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    
    
    @IBAction func pickFromLibrary(sender: AnyObject) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(pickerController, animated: true, completion: nil)
        
    }
    
    @IBAction func pickFromCamera(sender: AnyObject) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(pickerController, animated: true, completion: nil)
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePickerView.image = image
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        shareButton.enabled = true
    }
    
    
    @IBAction func shareMeme(sender: AnyObject) {
        memedImage = generateMemedImage()
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = save
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func cancelEdit(sender: AnyObject) {
        imagePickerView.image = nil
        shareButton.enabled = false
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        subscribeToKeyboardNotifications(textField)
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        setDefaultText()
        unsubscribeFromKeyboardNotifications()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func subscribeToKeyboardNotifications(textField: UITextField) {
        if textField == bottomTextField {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += getKeyboardHeight(notification)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        canDismissKeyboard = true
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userinfo = notification.userInfo
        let keboardSize = userinfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keboardSize.CGRectValue().height
    }
    
    func dismissKeyboard() {
        if canDismissKeyboard == true {
            canDismissKeyboard = false
            view.endEditing(true)
        }
    }
    
    func save(activityType:String?, completed:Bool, returnItems: [AnyObject]?, error:NSError?) {
        if !completed {
            return
        }
        meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, image: imagePickerView.image!, memedImage: memedImage, context: sharedContext)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.memes.append(meme)
        CoreDataStackManager.sharedInstance().saveContext()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func generateMemedImage() -> UIImage {
        
        navigationController?.navigationBarHidden = true
        bottomToolBar.hidden = true
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        navigationController!.navigationBarHidden = false
        bottomToolBar.hidden = false
        
        return memedImage
    }
    
    func setDefaultText() {
        topTextField.defaultTextAttributes = memeTextAttributes
        if topTextField.text == "" {
            topTextField.text = "TOP"
        }
        topTextField.textAlignment = NSTextAlignment.Center
        
        
        bottomTextField.defaultTextAttributes = memeTextAttributes
        if bottomTextField.text == "" {
            bottomTextField.text = "BOTTOM"
        }
        bottomTextField.textAlignment = NSTextAlignment.Center
    }
    
    
    
}

