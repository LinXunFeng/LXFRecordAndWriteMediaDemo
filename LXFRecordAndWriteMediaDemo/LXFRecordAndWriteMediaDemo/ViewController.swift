//
//  ViewController.swift
//  LXFRecordAndWriteMediaDemo
//
//  Created by 林洵锋 on 2017/7/15.
//  Copyright © 2017年 LXF. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    fileprivate lazy var session: AVCaptureSession = AVCaptureSession()
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var videoInput: AVCaptureDeviceInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1.初始化视频的输入输出
        setupVideoInputOutput()
        
        // 2.初始化音频的输入输出
        setupAudioInputOutput()
    }
}

// MARK:- 对采集的控制器方法
extension ViewController {
    // 开始采集
    @IBAction func start() {
        // 初始化一个预览图层
        setupPreviewLayer()
        session.startRunning()
    }
    // 停止采集
    @IBAction func stop() {
        session.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
    // 切换镜头
    @IBAction func rotate() {
        // 1.取出之前镜头的方向
        guard let videoInput = videoInput else { return }
        let position: AVCaptureDevicePosition = videoInput.device.position == .front ? .back : .front
        
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else { return }
        guard let device = devices.filter({ $0.position == position }).first else { return }
        guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 2.移除之前的input，添加新的input
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        session.commitConfiguration()
        
        // 3.保存最新的input
        self.videoInput = newInput
    }
}

// MARK:- 初始化方法
extension ViewController {
    fileprivate func setupVideoInputOutput() {
        // 1.添加视频的输入
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else { return }
        guard let device = devices.filter({ $0.position == .front }).first else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = input
        
        // 2.添加视频的输出
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput = output
        
        // 3.添加输入与输出
        addInputOutputToSession(input, output)
    }
    
    fileprivate func setupAudioInputOutput() {
        // 1.添加音频输入
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        
        // 2.添加音频输出
        let output = AVCaptureAudioDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        
        // 3.添加输入输出
        addInputOutputToSession(input, output)
    }
    
    private func addInputOutputToSession(_ input: AVCaptureInput, _ output: AVCaptureOutput) {
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
    
    fileprivate func setupPreviewLayer() {
        // 1.创建预览图层
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: session) else {return}
        
        // 2.设置previewLayer属性
        previewLayer.frame = view.bounds
        
        // 3.将图层添加到控制器的view的layer中
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if videoOutput?.connection(withMediaType: AVMediaTypeVideo) == connection {
            print("采集到视频数据")
        } else {
            print("采集到音频数据")
        }
    }
}

