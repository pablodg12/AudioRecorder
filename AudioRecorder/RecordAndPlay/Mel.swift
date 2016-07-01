//
//  Mel.swift
//  RecordAndPlay
//
//  Created by Pablo on 6/20/16.
//  Copyright © 2016 Nimble Chapps. All rights reserved.
//

import Foundation
import Accelerate


class Mel{
    var matrix = Array<Array<Float>>()
    var energy = Array(count:4410, repeatedValue:Array(count:64, repeatedValue:Float()))
    var matrixFilter = Array(count:26, repeatedValue:Array(count:64, repeatedValue:Float()))
    var matrixA = Array(count:101, repeatedValue:Array(count:27, repeatedValue:Float()))
    var matrixB = Array(count:101, repeatedValue:Array(count:4, repeatedValue:Float()))
    var signal : [Float] = []
    var mean : [Float] = []
    var desviation: [Float] = []
    var mirror : [Float] = []
    var dummy : [Float] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    var sample : Int = 0
    var rate: Int = 88200
    var samRate: Int = 0
    var sizeR: Int = 0
    var iteration: Int = 0
    var NumColumns: Int = 0
    let fft_weights: FFTSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(128))), FFTRadix(kFFTRadix2))
    var result = Array(count:64,repeatedValue:Float(0))
    var cosa = Array(count: 26, repeatedValue:Float())
    

    
// Manejo de arrays
    func vMinus(array1: [Float], array2:[Float]){ // Resta de vectors
        for k in 0...sample{
            mirror[k] = array1[k] - array2[k]
        }
    }
    func vDivision  (array1: [Float], array2:[Float]){ //Division de Vectores
        for k in 0...sample{
            mirror[k] = array1[k]/array2[k]
        }
    }
    func vSum(array1: [Float], array2:[Float]){ // Suma de vectores
        for k in 0...sample{
            mirror[k] = array1[k] + array2[k]
        }
    }
    func vMultiplication(array1: [Float], array2:[Float] ){ //Multiplicacion de Vectores
        for k in 0...sample{
            mirror[k] = array1[k] + array2[k]
        }
    }
    func eMultiplication(array1:[Float], escalar: Float){ //Multplicacion vector-escalar
        for k in 0...sample{
            mirror[k] = array1[k] * escalar
        }
    }
    func eSum(array1:[Float], escalar: Float){ //Suma vector-escalar
        for k in 0...sample{
            mirror[k] = array1[k] + escalar
        }
    }
    func eMinus(array1:[Float], escalar: Float){ //Resta vector-escalar
        for k in 0...sample{
            mirror[k] = array1[k] - escalar
        }
    }
    func eDivision(array1:[Float], escalar: Float)-> [Float]{// Division vector-escalar
        var aux: [Float] = []
        for k in 0...127{
            aux.append(array1[k] / escalar)
        }
        return aux
    }
    func length(){ // Tamaño de la señal
        for _ in signal{
            self.sample = self.sample + 1
        }
    }
    
// Set de arrays
    func setSignal(array1: [Float]){
        self.sample = 0
        self.samRate = 0
        self.sizeR = 0
        self.iteration = 0
        self.NumColumns = 0
        signal = array1
        length()
    }
    func setMean(array1: [Float]){
        mean = array1
    }
    func setDesviation(array1: [Float]){
        desviation = array1
    }
// Funciones necesarias para el manejo del audio
    
    func standardization(mean: [Float], desviation:[Float]){
        vMinus(signal, array2: mean)
        vDivision(mirror,array2: desviation)
        signal = mirror
        mirror = []
    }
    
// Funcion que corta la onda en frames, usando 50% de overlapping.
    func overlapping(){
        samRate = (sample/rate)*1000
        sizeR = samRate/20
        iteration = sample/sizeR - 1
        NumColumns = (3/2)*sample/sizeR
        
        for _ in 0...NumColumns {
                matrix.append(Array(count:sizeR, repeatedValue:Float()))
        }
        
        matrix[0][0...(sizeR-1)] = signal[0...(sizeR-1)]
        matrix[1][0...(sizeR-1)] = signal[(sizeR - sizeR/2)...((2*sizeR-sizeR/2)-1)]
        for i in 2...iteration{
            if i%2 == 0 {
                if signal[(i-1)*sizeR...i*sizeR].count != sizeR {
                    matrix[i][0...(sizeR-1)] = signal[(i-1)*sizeR...(i*sizeR-1)]
                }
                else{
                    matrix[i][0...(sizeR-1)] = signal[(i-1)*sizeR...(i*sizeR)]
                }
            }
            if i%2 == 1{
                if signal[(i*sizeR-sizeR/2)...((i+1)*sizeR-sizeR/2)].count != sizeR{
                    matrix[i][0...(sizeR-1)] = signal[(i*sizeR-sizeR/2)...((i)*sizeR+sizeR/2 - 1)]
                }
                else{
                    matrix[i][0...(sizeR-1)] = signal[(i*sizeR-sizeR/2)...((i)*sizeR+sizeR/2)]
                }
            }
        }
    }
    // Prepara la Data para la transformada de fourier
    func PreFourier(){
        for k in 0...NumColumns{
            matrix[k] = matrix[k] + dummy
        }
    }
    
    // Funcion para realizar la transformada de fourier, obteniendo la energia
    func fft(var inputArray:[Float]) -> [Float] {
        var fftMagnitudes = [Float](count:inputArray.count, repeatedValue:0.0)
        var zeroArray = [Float](count:inputArray.count, repeatedValue:0.0)
        var splitComplexInput = DSPSplitComplex(realp: &inputArray, imagp: &zeroArray)
        
        vDSP_fft_zip(fft_weights, &splitComplexInput, 1, vDSP_Length(log2(CFloat(inputArray.count))), FFTDirection(FFT_FORWARD));
        
        vDSP_zvmags(&splitComplexInput, 1, &fftMagnitudes, 1, vDSP_Length(inputArray.count));
        
        return fftMagnitudes
    }
    
    func performeFFt(){
        for i in 0...NumColumns{
            energy[i][0...63] = eDivision(fft(matrix[i]),escalar: 128.0)[0...63]
        }
    }
    
    
    func fillMatrix(file: String, col: Int, row: Int) {
        var lineArr: [String]
        var columnNumber: Int = 0
        var lineNumber: Int = 0
        var fileArr: [String] = file.componentsSeparatedByString(".")
        var fileName: String = fileArr[0]
        var fileExtension: String = fileArr[1]
        var inputArr = Array(count:row, repeatedValue:Array(count:col, repeatedValue:Float()))
        // Encontrar el archivo
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType:fileExtension) {
            // use path
            if let aStreamReader = StreamReader(path: path) {
                defer {
                    aStreamReader.close()
                }
                //Mientras que queda linea
                while let line = aStreamReader.nextLine() {
                    lineArr  = line.componentsSeparatedByString(" ")
                    //matrixFilter[columnNumber] = lineArr
                    lineNumber = 0
                    //Otra solucion
                    for  number in lineArr {
                        //matrixFilter[columnNumber][lineNumber] = (number as NSString).floatValue
                        inputArr[columnNumber][lineNumber] = (number as NSString).floatValue
                        lineNumber += 1
                    }
                    columnNumber += 1
                }
                switch fileName{
                case "weigtha":
                    matrixA = inputArr
                case "filter":
                    matrixFilter = inputArr
                case "weigthb":
                    matrixB = inputArr
                default:
                    break;
                }
                
            }
        }
    }
    
    func vecArrMult(arrM1: [Float], arrM2: [Float]) -> [Float]{
        var arrRes = Array(count: arrM1.count, repeatedValue:Float())
        var counter : Int = 0
        for _ in 1...arrM1.count{
            arrRes[counter] = arrM1[counter] * arrM2[counter]
            counter += 1
        }
        return arrRes
    }
    
    func vecMatrixMult(tempMatrix: [[Float]], tempVec: [Float]){
        var matrixRes = Array(count:tempMatrix.count, repeatedValue:Array(count:tempVec.count, repeatedValue:Float()))
        var counter: Int = 0
        for _ in 1...tempMatrix.count{
            matrixRes[counter] = vecArrMult(tempMatrix[counter], arrM2: tempVec)
            counter += 1
        }
        cosa = sumMatrixColumn(matrixRes)
    }
    
    func sumMatrixColumn(inMatrix: [[Float]]) -> [Float]{
        var sumArr = Array(count: inMatrix.count, repeatedValue:Float())
        var counter: Int
        counter = 0
        for linea in inMatrix{
            for element in linea{
                sumArr[counter] += element
            }
            sumArr[counter] = log10(sumArr[counter])
            counter += 1
        }
        return sumArr
    }
    
    
    
    func suma(){
        for k in 0...(64-1){
            var suma:Float = 0.0
            for m in 0...(4410-1){
                suma = suma + energy[m][k]
            }
            result[k] = suma
        }
    }
    
    func log10(val: Float) -> Float {
        return log(val)/log(10.0)
    }
    
    
    
    
}