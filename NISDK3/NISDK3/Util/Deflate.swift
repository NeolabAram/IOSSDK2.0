/*
 * DeflateSwift (deflate.swift)
 *
 * Copyright (C) 2015 ONcast, LLC. All Rights Reserved.
 * Created by Josh Baker (joshbaker77@gmail.com)
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 * https://github.com/tidwall/DeflateSwift/blob/master/deflate.swift
 */


import Foundation

class ZStream {
    fileprivate struct z_stream {
        fileprivate var next_in : UnsafePointer<UInt8>? = nil
        fileprivate var avail_in : CUnsignedInt = 0
        private var total_in : CUnsignedLong = 0
        
        fileprivate var next_out : UnsafePointer<UInt8>? = nil
        fileprivate var avail_out : CUnsignedInt = 0
        private var total_out : CUnsignedLong = 0
        
        private var msg : UnsafePointer<CChar>? = nil
        private var state : OpaquePointer? = nil
        
        private var zalloc : OpaquePointer? = nil
        private var zfree : OpaquePointer? = nil
        private var opaque : OpaquePointer? = nil
        
        private var data_type : CInt = 0
        private var adler : CUnsignedLong = 0
        private var reserved : CUnsignedLong = 0
    }
    
    @_silgen_name("zlibVersion") private static func zlibVersion() -> OpaquePointer
    @_silgen_name("deflateInit2_") private func deflateInit2(strm : UnsafeMutableRawPointer, level : CInt, method : CInt, windowBits : CInt, memLevel : CInt, strategy : CInt, version : OpaquePointer, stream_size : CInt) -> CInt
    @_silgen_name("deflateInit_") private func deflateInit(strm : UnsafeMutableRawPointer, level : CInt, version : OpaquePointer, stream_size : CInt) -> CInt
    @_silgen_name("deflateEnd") private func deflateEnd(strm : UnsafeMutableRawPointer) -> CInt
    @_silgen_name("deflate") private func deflate(strm : UnsafeMutableRawPointer, flush : CInt) -> CInt
    @_silgen_name("inflateInit2_") private func inflateInit2(strm : UnsafeMutableRawPointer, windowBits : CInt, version : OpaquePointer, stream_size : CInt) -> CInt
    @_silgen_name("inflateInit_") private func inflateInit(strm : UnsafeMutableRawPointer, version : OpaquePointer, stream_size : CInt) -> CInt
    @_silgen_name("inflate") private func inflate(strm : UnsafeMutableRawPointer, flush : CInt) -> CInt
    @_silgen_name("inflateEnd") private func inflateEnd(strm : UnsafeMutableRawPointer) -> CInt
    
    private static var c_version : OpaquePointer = ZStream.zlibVersion()
    private(set) static var version : String = String(format: "%s", locale: nil, c_version)
    
    private func makeError(res : CInt) -> NSError? {
        var err = ""
        switch res {
        case 0: return nil
        case 1: err = "stream end"
        case 2: err = "need dict"
        case -1: err = "errno"
        case -2: err = "stream error"
        case -3: err = "data error"
        case -4: err = "mem error"
        case -5: err = "buf error"
        case -6: err = "version error"
        default: err = "undefined error"
        }
        return NSError(domain: "deflateswift", code: -1, userInfo: [NSLocalizedDescriptionKey:err])
    }
    
    fileprivate var strm = z_stream()
    fileprivate var deflater = true
    private var initd = false
    fileprivate var init2 = false
    fileprivate var level = CInt(-1)
    fileprivate var windowBits = CInt(15)
    private var out = [UInt8](repeating: 0, count: 5000)
    public init() { }
    public func write( bytes : [UInt8], flush: Bool) -> (bytes: [UInt8], err: NSError?){
        var bytes = bytes
        var res : CInt
        if !initd {
            if deflater {
                if init2 {
                    res = deflateInit2(strm: &strm, level: level, method: 8, windowBits: windowBits, memLevel: 8, strategy: 0, version: ZStream.c_version, stream_size: CInt(MemoryLayout<z_stream>.size))
                } else {
                    res = deflateInit(strm: &strm, level: level, version: ZStream.c_version, stream_size: CInt(MemoryLayout<z_stream>.size))
                }
            } else {
                if init2 {
                    res = inflateInit2(strm: &strm, windowBits: windowBits, version: ZStream.c_version, stream_size: CInt(MemoryLayout<z_stream>.size))
                } else {
                    res = inflateInit(strm: &strm, version: ZStream.c_version, stream_size: CInt(MemoryLayout<z_stream>.size))
                }
            }
            if res != 0{
                return ([UInt8](), makeError(res: res))
            }
            initd = true
        }
        var result = [UInt8]()
        strm.avail_in = CUnsignedInt(bytes.count)
        strm.next_in = &bytes+0
        repeat {
            strm.avail_out = CUnsignedInt(out.count)
            strm.next_out = &out+0
            if deflater {
                res = deflate(strm: &strm, flush: flush ? 1 : 0)
            } else {
                res = inflate(strm: &strm, flush: flush ? 1 : 0)
            }
            if res < 0 {
                return ([UInt8](), makeError(res: res))
            }
            let have = out.count - Int(strm.avail_out)
            if have > 0 {
                result += Array(out[0...have-1])
            }
        } while (strm.avail_out == 0 && res != 1)
        if strm.avail_in != 0 {
            return ([UInt8](), makeError(res: -9999))
        }
        return (result, nil)
    }
    deinit{
        if initd{
            if deflater {
                _ = deflateEnd(strm: &strm)
            } else {
                _ = inflateEnd(strm: &strm)
            }
        }
    }
}

class DeflateStream : ZStream {
    convenience public init(level : Int){
        self.init()
        self.level = CInt(level)
    }
    convenience public init(windowBits: Int){
        self.init()
        self.init2 = true
        self.windowBits = CInt(windowBits)
    }
    convenience public init(level : Int, windowBits: Int){
        self.init()
        self.init2 = true
        self.level = CInt(level)
        self.windowBits = CInt(windowBits)
    }
}

class InflateStream : ZStream {
    override public init(){
        super.init()
        deflater = false
    }
    convenience public init(windowBits: Int){
        self.init()
        self.init2 = true
        self.windowBits = CInt(windowBits)
    }
}
