import UIKit
import SceneKit
import ARKit


//Inspired by Jayven Nhan Scenekit demo, Sri Adatrao ARkit detecting planes, Benjamin Kindle
//article


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var e:EchoAR!;
    var planeColor: UIColor?
    var planeColorOff: UIColor?
    var myPlaneNode: SCNNode?
    var myPlanes: [SCNNode] = []
    
    let treeId = "a3afa700-c20a-4366-9441-64ea0a14f750"
    
    //picnic table
    let picnicTableId = "ddb22b24-1acc-41a6-825d-fb2d78040f9c"
    
    let roadId = "32b22856-24af-43c4-bbbe-88ad98998a46"
    
    //pool
    let poolId = "0916c8f6-5d31-4b66-9bf4-a5b1f4e6509f"

    //mailbox
    let mailBoxId = "3952a84c-0b6a-4917-9e89-89bc7c318590"
    
    let houseId = "a294665c-7e9c-4d15-96de-fb750afded31"

    //deer
    let deerId = "d356f8f6-1f60-4613-a108-80eb50ae3ded"
    
    
    let bikeId = "5c76694e-ec84-411e-b85c-670439717932"

    
    @IBOutlet weak var togglePlaneButton: UIButton!
    
    @IBOutlet weak var treeButton: UIButton!
    
    @IBOutlet weak var roadButton: UIButton!
    
    @IBOutlet weak var poolButton: UIButton!
    
    @IBOutlet weak var ballParkButton: UIButton!
    
    @IBOutlet weak var mailBoxButton: UIButton!
    
    @IBOutlet weak var houseButton: UIButton!
    
    @IBOutlet weak var deerButton: UIButton!
    
    @IBOutlet weak var dragButton: UIButton!
    
    @IBOutlet weak var rotateButton: UIButton!

    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var addButton: UIButton!

    @IBOutlet weak var bikeButton: UIButton!
    
    var panStartZ: CGFloat?
    var draggingNode: SCNNode?
    var lastPanLocation: SCNVector3?
    

    var selectedId: String?
    var selectedInd = 0
    var idArr: [String]?
    var scaleConstants: [CGFloat]?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set all model choice button alpha's to the deselect state
        resetChoiceButtonAlphas()
        
        //select the treeId, by making it's entyr id the selected id
        //and by updating it's button alpha to the selected state
        selectedId = treeId
        treeButton.alpha = 1.0
        
        //set all edit button alpha's to the deselect state
        resetEditButtonAlphas()
        //set the add button alpha to the selected state
        addButton.alpha = 1.0
        
        //array of all entry id's of models users can add
        idArr = [treeId, roadId, poolId, picnicTableId, mailBoxId, houseId, deerId, bikeId]
        
        //default scale constants for the objects (reducing their size to start)
        scaleConstants = [0.009, 0.0004, 0.002, 0.0001, 0.004, 0.003, 0.0004, 0.000013]

        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true

        e = EchoAR();
        
        //choose a color to use for the plane
        planeColor = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.6))
        planeColorOff = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.0))


        //create and add a recognizer to respond to taps on the scene view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addObjToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //create and add a recognizer to respond to finger pans on the scene view
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        sceneView.addGestureRecognizer(panRecognizer)
        
        //create and add a recognizer to respond to finger pinchs on the scene view
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRecognizer:)))
        sceneView.addGestureRecognizer(pinchRecognizer)

        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //configure scene view session to detect horizontal planes
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
       
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        //sceneView.session.pause()
    }
    
    @objc func handlePinch(pinchRecognizer: UIPinchGestureRecognizer){
        //call do scale to scale node on user pinch gesture
        doScale(recognizer: pinchRecognizer)
    }
    
    @objc func addObjToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer){
        //get location of the tap gesture
        let tapLocation = recognizer.location(in: sceneView)

        //if delete is selected
        if self.deleteButton.alpha == 1 {
            //use hit test to get the node tapped
            guard let hitNodeResult = sceneView.hitTest(tapLocation, options: nil).first else {return}
            
            //if the node is a plain node return
            if(hitNodeResult.node.name == "plain"){
               return
            }
            
            //delete tapped node
            hitNodeResult.node.removeFromParentNode()
        }
        else if self.addButton.alpha == 1 {
            //if add selected, add a new node
            doAdd(withGestureRecognizer: recognizer)
        }
    }
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer){
        //if drag button is selected drag the touched node on pan gesture
        /// but if rotate is selected rotate the node
        if self.dragButton.alpha == 1 {
            doDrag(panGesture: panGesture)
        }
        else if self.rotateButton.alpha == 1{
            doRotate(rotateGesture: panGesture)
        }
    }
    
    func doScale(recognizer: UIPinchGestureRecognizer){
        //get the location of the pinch
        let location = recognizer.location(in: sceneView)
        
        //get the node touched by pinch
        guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else {return}
        if(isPlane(node: hitNodeResult.node)){
            return
        }
        //if the pinch has begun, or continues
        if recognizer.state == .began || recognizer.state == .changed {
            //scale the touched node
            let action = SCNAction.scale(by: recognizer.scale, duration: 0.3)
            hitNodeResult.node.runAction(action)
            recognizer.scale = 1.0
        }
    }
    
    func doAdd(withGestureRecognizer recognizer: UIGestureRecognizer){
        //get the location of the tap
        let tapLocation = recognizer.location(in: sceneView)

        
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = SCNVector3Make(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        
        e.loadSceneFromEntryID(entryID: idArr![selectedInd]) { (selectedScene) in
            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}
            selectedNode.position = SCNVector3(x,y,z)
            let action = SCNAction.scale(by: scaleConstants![selectedInd], duration: 0.3)
            selectedNode.runAction(action)
            if selectedInd == 6 {
                selectedNode.eulerAngles.y = .pi
            }
            selectedNode.name = idArr![selectedInd]
            sceneView.scene.rootNode.addChildNode(selectedNode)
        }
    }
    
    func doDrag(panGesture: UIPanGestureRecognizer){
        guard let view = self.sceneView else {return}
        let location = panGesture.location(in: self.view)
        print("begin pan")
        switch panGesture.state {
        case .began:
            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else {return}
            if(isPlane(node: hitNodeResult.node)){
                return
            }
            lastPanLocation = hitNodeResult.worldCoordinates
            panStartZ = CGFloat(view.projectPoint(lastPanLocation!).z)
            draggingNode = hitNodeResult.node
        case .changed:
            guard lastPanLocation != nil, draggingNode != nil, panStartZ != nil else {return}
            let location = panGesture.location(in: view)
            let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))
            draggingNode?.worldPosition = worldTouchPosition
        case .ended:
            lastPanLocation = nil
            draggingNode = nil
            panStartZ = nil
        default:
            break
        }
    }
    func doRotate(rotateGesture: UIPanGestureRecognizer){
        guard let view = self.sceneView else {return}
        let location = rotateGesture.location(in: self.view)
        if rotateGesture.state == .began || rotateGesture.state == .changed {
            guard let hitNodeResult = view.hitTest(location, options: nil).first else {return}
            if(isPlane(node: hitNodeResult.node)){
                return
            }
            hitNodeResult.node.runAction(SCNAction.rotateBy(x: 0.0, y: 0.08, z: 0.0, duration: 0.5))
        }
    }
    

    func resetChoiceButtonAlphas(){
        treeButton.alpha = 0.3
        roadButton.alpha = 0.3
        poolButton.alpha = 0.3
        ballParkButton.alpha = 0.3
        mailBoxButton.alpha = 0.3
        houseButton.alpha = 0.3
        deerButton.alpha = 0.3
        bikeButton.alpha = 0.3
    }
    
    func resetEditButtonAlphas(){
        dragButton.alpha = 0.3
        rotateButton.alpha = 0.3
        deleteButton.alpha = 0.3
        addButton.alpha = 0.3
}

    @IBAction func choiceButtonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        resetChoiceButtonAlphas()
        button.alpha = 1.0
        selectedInd = button.tag
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        resetEditButtonAlphas()
        button.alpha = 1.0
    }
    
    @IBAction func togglePlaneTapped(_ sender: Any) {
        for plane in myPlanes {
               togglePlane(planeNode: plane)
        }
        togglePlaneButton.alpha = togglePlaneButton.alpha < 0.5 ? 1.0 : 0.3
        print(togglePlaneButton.alpha)
    }
    
    func togglePlane(planeNode: SCNNode){
        if togglePlaneButton.alpha.isEqual(to: 1.0) {
           planeNode.geometry?.materials.first?.diffuse.contents = planeColorOff
        }
        else {
            planeNode.geometry?.materials.first?.diffuse.contents = planeColor
        }
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else {return}
        
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        plane.width = w
        plane.height = h

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: w, height: h)
        
        plane.materials.first?.diffuse.contents = planeColor!
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.name = "plain"
        myPlaneNode = planeNode
        myPlanes.append(planeNode)
        
        node.addChildNode(planeNode)
    }
    
    func isPlane(node: SCNNode) -> Bool {
        guard  let name = node.name else {
            return false
        }
        if name == "plain"{
            return true
        }
        return false
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
