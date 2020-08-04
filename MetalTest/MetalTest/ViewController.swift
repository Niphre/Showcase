//
//  ViewController.swift
//  MetalTest
//
//  Created by Isaac Snediker-Morscheck on 9/22/19.


import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var mtkView: MTKView!
    var renderer: Renderer!
    
    let device = MTLCreateSystemDefaultDevice()!
    
    
    override func viewDidLoad() {

        mtkView = MTKView()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mtkView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        
        //set up device and buffer formats
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        renderer = Renderer(view: mtkView, device: device)
        mtkView.delegate = renderer
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

