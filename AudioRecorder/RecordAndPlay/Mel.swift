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
    func eDivision(array1:[Float], escalar: Float){// Division vector-escalar
        for k in 0...sample{
            mirror[k] = array1[k] / escalar
        }
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
            matrix[i] = fft(matrix[i])
        }
    }
    
    
    
    
    
}