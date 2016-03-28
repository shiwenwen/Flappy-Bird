//
//  GameScene.swift
//  Flappy Bird
//
//  Created by sww on 16/3/27.
//  Copyright (c) 2016年 sww. All rights reserved.
//
//多边形工具 http://stackvoerflow.com/questions/19040144
import SpriteKit
enum 图层:CGFloat {
    case 背景
    case 障碍物
    case 前景
    case 游戏角色
    case UI层
}
enum  游戏状态{
    case 主菜单
    case 教程
    case 游戏
    case 跌落
    case 显示分数
    case 结束
}
struct 物理层 {
    static let 无:UInt32 = 0
    static let 游戏角色:UInt32 = 0b1  //1
    static let 障碍物:UInt32 = 0b10  //2
    static let 地面:UInt32 = 0b110   //4
}
class GameScene: SKScene ,SKPhysicsContactDelegate{
    let k前景地面数 = 2
    let k前景移动速度:CGFloat = -150.0
    let k重力 :CGFloat = -1500.0
    let k上冲速度:CGFloat = 400
    let k底部障碍最小乘数: CGFloat = 0.1
    let k底部障碍最大乘数:CGFloat = 0.6
    let k缺口系数:CGFloat = 3.5
    let k首次生成障碍延迟:NSTimeInterval = 1.75
    let k每次再生障碍延迟:NSTimeInterval = 1.5
    let k顶部留白:CGFloat = 20
    let k标签字体 = "HelveticaNeue-CondensedBlack"
    var 得分标签:SKLabelNode!
    var 当前分数 = 0
    var 撞击了地面 = false
    var 撞击了障碍物 = false
    var 当前的游戏状态:游戏状态 = .游戏
    var 当前障碍物的标签 = 0
    
    var  速度 = CGPointZero
    
    let 世界单位 = SKNode()

    var 游戏区域起始点:CGFloat = 0.0
    var 游戏区域的高度:CGFloat = 0.0
    let 主角 = SKSpriteNode(imageNamed:"Bird0")
    let 帽子 = SKSpriteNode(imageNamed:"Sombrero")
    var  上一次更新时间:NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    
    
    
    //  创建音效
    let 叮的音效 = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let 拍打的音效 = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let 摔倒的音效 = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let 下落的音效 = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let 撞击地面的音效 = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let 砰的音效 = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let 得分的音效 = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
    
    override func didMoveToView(view: SKView) {
        
        //关闭重力
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        addChild(世界单位)
            设置背景()
            设置前景()
            设置主角()
            设置得分标签()
            无限重生障碍()
          }
    func 设置背景(){
        
        let 背景 = SKSpriteNode(imageNamed:"Background")
        
        背景.anchorPoint = CGPointMake(0.5, 1.0)
        背景.position = CGPointMake(size.width/2, size.height)
        背景.zPosition = 图层.背景.rawValue
        
        世界单位.addChild(背景)
        
        游戏区域起始点  = size.height - 背景.size.height
        
        游戏区域的高度 = 背景.size.height
        let 左下 = CGPointMake(0, 游戏区域起始点)
        let 右下 = CGPointMake(size.width, 游戏区域起始点)
        self.physicsBody = SKPhysicsBody(edgeFromPoint: 左下, toPoint: 右下)
        self.physicsBody?.categoryBitMask = 物理层.地面
        self.physicsBody?.contactTestBitMask = 物理层.游戏角色

    }
    func 设置前景 (){
        
        for i in 0..<k前景地面数 {
            let 前景 = SKSpriteNode(imageNamed:"Ground")
            
            前景.anchorPoint = CGPointMake(0.0, 1.0)
            前景.position = CGPointMake(size.width * CGFloat(i), 游戏区域起始点)
            前景.zPosition = 图层.前景.rawValue
            前景.name = "前景"
                
            世界单位.addChild(前景)
        }
       
        
        
    }
    func 设置得分标签(){
        
        得分标签 = SKLabelNode(fontNamed:k标签字体)
        得分标签.fontColor = SKColor(red: 101.0/255.0, green: 71/255.0, blue: 73/255.0, alpha: 1)
        得分标签.position = CGPoint(x: size.width / 2, y: size.height - k顶部留白)
        得分标签.verticalAlignmentMode = .Top //顶部对齐
        得分标签.text = "0"
        得分标签.zPosition = 图层.UI层.rawValue
        世界单位.addChild(得分标签)
        
    }
    //:###游戏流程
    func 创建障碍物(图片:String) -> SKSpriteNode {
        
        let 障碍物 = SKSpriteNode(imageNamed: 图片)
        障碍物.zPosition = 图层.障碍物.rawValue
        障碍物.userData = NSMutableDictionary()
        let offsetX = 障碍物.size.width * 障碍物.anchorPoint.x
        let offsetY = 障碍物.size.height * 障碍物.anchorPoint.y
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 4 - offsetX, 0 - offsetY)
        CGPathAddLineToPoint(path, nil, 7 - offsetX, 307 - offsetY)
        CGPathAddLineToPoint(path, nil, 47 - offsetX, 308 - offsetY)
        CGPathAddLineToPoint(path, nil, 48 - offsetX, 1 - offsetY)
         CGPathCloseSubpath(path)
        
        障碍物.physicsBody = SKPhysicsBody(polygonFromPath: path)
        
       
        障碍物.physicsBody?.categoryBitMask = 物理层.障碍物
        障碍物.physicsBody?.collisionBitMask = 0 //关闭碰撞处理
        障碍物.physicsBody?.contactTestBitMask = 物理层.游戏角色

        return 障碍物
        
    }
    
    func 生成障碍()  {
        
        let 底部障碍 = 创建障碍物("CactusBottom")
        let 起始x坐标 = size.width + 底部障碍.size.width / 2
        
        let Y最小坐标:CGFloat = (游戏区域起始点 - 底部障碍.size.height / 2 + 游戏区域的高度 * k底部障碍最小乘数)
        let Y最大坐标:CGFloat = (游戏区域起始点 - 底部障碍.size.height / 2 + 游戏区域的高度 * k底部障碍最大乘数)
     
        底部障碍.position = CGPointMake(起始x坐标, CGFloat.random(min: Y最小坐标, max: Y最大坐标))
        
 
        
        let 顶部障碍 = 创建障碍物("CactusTop")
        世界单位.addChild(底部障碍)
//        顶部障碍.zRotation = CGFloat(180).degreesToRadians()
        

        顶部障碍.position = CGPointMake(起始x坐标, 底部障碍.position.y + 底部障碍.size.height / 2 + 顶部障碍.size.height / 2 + 主角.size.height * k缺口系数)
        
        世界单位.addChild(顶部障碍)
        let 上标签:SKLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        上标签.text = "\(当前障碍物的标签)"
        上标签.verticalAlignmentMode = .Center
        上标签.zPosition = 图层.UI层.rawValue
        上标签.fontColor = SKColor(red: 101.0/255.0, green: 71/255.0, blue: 73/255.0, alpha: 1)
        print("\(顶部障碍.position)")
        
        上标签.position = CGPoint(x: 0, y: -(顶部障碍.position.y - size.height + 顶部障碍.size.height / 2) / 2)
        顶部障碍.addChild(上标签)

        
        let X皱移动距离 = -(size.width + 底部障碍.size.width)
        let 移动的持续时间 = X皱移动距离 / k前景移动速度
        
        let 移动的动作队列 = SKAction.sequence([
            
            SKAction.moveByX(X皱移动距离, y: 0, duration: NSTimeInterval(移动的持续时间)),
            SKAction.removeFromParent()
                
                
            ])
        
        
        顶部障碍.name = "顶部障碍"
        底部障碍.name = "底部障碍"
        顶部障碍.runAction(移动的动作队列)
        底部障碍.runAction(移动的动作队列)
        当前障碍物的标签++
        
    }
    func 无限重生障碍() {
        
        let 首次延迟 = SKAction.waitForDuration(k首次生成障碍延迟)
        
//        let 重生障碍 = SKAction.runBlock { ()-> Void in
//            
//            return self.生成障碍()
//        }
            let 重生障碍 = SKAction.runBlock(生成障碍)
        
        let 每次重生间隔 = SKAction.waitForDuration(k每次再生障碍延迟)
        let 重生的动作队列 = SKAction.sequence([重生障碍,每次重生间隔])
        let 无限重生 = SKAction.repeatActionForever(重生的动作队列)
        
        let 总的动作队列 = SKAction.sequence([首次延迟,无限重生])
        runAction(总的动作队列,withKey: "重生")
    }
    func 停止重生障碍() {
        removeActionForKey("重生")
        
        世界单位.enumerateChildNodesWithName("顶部障碍") { (匹配单位, _) in
            
            匹配单位.removeAllActions()
        }
        世界单位.enumerateChildNodesWithName("底部障碍") { (匹配单位, _) in
            
            匹配单位.removeAllActions()
        }
    }
    func 设置主角(){
        主角.position = CGPointMake(size.width * 0.2,游戏区域的高度 * 0.5 + 游戏区域起始点)
        主角.zPosition = 图层.游戏角色.rawValue
        let offsetX = 主角.size.width * 主角.anchorPoint.x
        let offsetY = 主角.size.width * 主角.anchorPoint.y
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 3 - offsetX, 12 - offsetY)
        CGPathAddLineToPoint(path, nil, 6 - offsetX, 20 - offsetY)
        CGPathAddLineToPoint(path, nil, 10 - offsetX, 22 - offsetY)
        CGPathAddLineToPoint(path, nil, 18 - offsetX, 22 - offsetY)
        CGPathAddLineToPoint(path, nil, 28 - offsetX, 27 - offsetY)
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 23 - offsetY)
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 9 - offsetY)
        CGPathAddLineToPoint(path, nil, 25 - offsetX, 4 - offsetY)
        CGPathAddLineToPoint(path, nil, 5 - offsetX, 2 - offsetY)
        
       
        
        主角.physicsBody = SKPhysicsBody(polygonFromPath: path)
        
        
        主角.physicsBody?.categoryBitMask = 物理层.游戏角色
        主角.physicsBody?.collisionBitMask = 0 //关闭碰撞处理
        主角.physicsBody?.contactTestBitMask = 物理层.障碍物|物理层.地面
         CGPathCloseSubpath(path)
        世界单位.addChild(主角)

        设置帽子()
    }
    func 更新主角(){
        
        let 加速度 = CGPoint(x: 0, y: k重力)
        速度 = 速度 + 加速度 * CGFloat(dt)
        
        主角.position = 主角.position + 速度 * CGFloat(dt)
        
        //撞击地面
        if 主角.position.y - 主角.size.height / 2 < 游戏区域起始点 {
            
            主角.position = CGPoint(x:主角.position.x,y:游戏区域起始点+主角.size.height/2)
        }
    }
    
    func 设置帽子() {
        
        帽子.position = CGPointMake(31-帽子.size.width/2, 30 - 帽子.size.height/2)
        主角.addChild(帽子)
        
        
      
        
        
        
    }
    func 更新前景(){
        //通过节点名查找节点
        世界单位.enumerateChildNodesWithName("前景") { (匹配单位, _) in
            
            if let 前景 = 匹配单位 as? SKSpriteNode{
                
                let 地面移动速度 = CGPointMake(self.k前景移动速度 , 0)
                
                前景.position += 地面移动速度 * CGFloat(self.dt)
                if 前景.position.x < -前景.size.width{
                    
                    前景.position += CGPointMake(前景.size.width * CGFloat(self.k前景地面数), 0)
                    
                }
                
            }
        }
        
    }
    
    func 撞击障碍物检查()  {
        if 撞击了障碍物 {
            撞击了障碍物 = false
          切换到跌落状态()
        }
        
    }
    func 撞击地面检查()  {
        if 撞击了地面 {
            撞击了地面  = false
            速度 = CGPointMake(0, 0)
            主角.zRotation = CGFloat(-90).degreesToRadians()
            主角.position = CGPointMake(主角.position.x, 游戏区域起始点 + 主角.size.width / 2)
            //        runAction(撞击地面的音效)
            切换到显示分数状态()

        }
   }
    func 更新得分(){
        世界单位.enumerateChildNodesWithName("顶部障碍") { (匹配单位, _) -> Void in
            
            if let 障碍物 = 匹配单位 as?SKSpriteNode{
                
                if let 已通过 = 障碍物.userData?["已通过"] as?NSNumber{
                    if 已通过.boolValue{
                        
                        return //已通过
                    }
                    
                }
                if self.主角.position.x > 障碍物.position.x + 障碍物.size.width / 2 + self.主角.size.width / 2{
                    
                    self.当前分数++
                    self.得分标签.text = "\(self.当前分数)"
                    self.runAction(self.得分的音效)
                    障碍物.userData?["已通过"] = NSNumber(bool: true)
                }
                
            }
            
        }
        
    }
    
    //MARK:游戏状态
    func 切换到跌落状态() {
        
        当前的游戏状态 = .跌落
        
        runAction(SKAction.sequence([
            摔倒的音效,
            SKAction.waitForDuration(0.1),
            下落的音效
            ]))
        
    主角.removeAllActions()
        
    停止重生障碍()
    }
    func 切换到显示分数状态() {
        
        当前的游戏状态 = .显示分数
         主角.removeAllActions()
      停止重生障碍()
        
    }
    func 重新开始游戏() {
        

                
          runAction(砰的音效) 
        let 新的游戏场景 = GameScene.init(size: size)
        let 切换特效 = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.025)
        view?.presentScene(新的游戏场景, transition: 切换特效)
        
    }
    
    //MARK:物理引擎
    func didBeginContact(contact: SKPhysicsContact) {
        let 被撞对象 = contact.bodyA.categoryBitMask == 物理层.游戏角色 ? contact.bodyB : contact.bodyA
        
        if 被撞对象.categoryBitMask == 物理层.地面 {
            
            print("撞击了地面")
            撞击了地面 = true
        }else if 被撞对象.categoryBitMask == 物理层.障碍物{
            print("撞击了障碍物")
            
            撞击了障碍物 = true
        }
        
        
    }
    
    
    func 主角飞一下(){
         runAction(拍打的音效)
        速度 = CGPoint (x:0,y:k上冲速度)
        //移动帽子
        let 向上移动 = SKAction.moveByX(0, y: 12, duration: 0.15)
            向上移动.timingMode = .EaseInEaseOut
        let 向下移动 = 向上移动.reversedAction()
        帽子.runAction(SKAction.sequence([向上移动,向下移动]))
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
       
        
       
        switch 当前的游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .游戏:
            主角飞一下()
            break
        case .跌落:
          
            break
        case .显示分数:
            
              重新开始游戏()
            break
        case .结束:
            break
        }
       
    }
   //MARK:更新
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        //每一帧都会调用
        
        if 上一次更新时间 > 0{
            
            dt = currentTime - 上一次更新时间
        }else{
            
            dt = 0
        }
        上一次更新时间 = currentTime
        
        //更新主角状态
//        更新主角()
//        更新前景()
//        撞击障碍物检查()
        switch 当前的游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .游戏:
              更新前景()
              更新主角()
              撞击障碍物检查()
              撞击地面检查()
              更新得分()
            break
        case .跌落:
            更新主角()
            撞击地面检查()
            break
        case .显示分数:
            break
        case .结束:
            break
        }

        
    }
}
