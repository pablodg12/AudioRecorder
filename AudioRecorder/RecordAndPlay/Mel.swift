//
//  Mel.swift
//  RecordAndPlay
//
//  Created by Pablo on 6/20/16.
//

import Foundation
import Accelerate
import Darwin


class Mel{
    let pi = Float(M_PI)
    var matrix = Array<Array<Float>>()
    var energy = Array(count:1850, repeatedValue:Array(count:256, repeatedValue:Float()))
    var matrixFilter = Array(count:26, repeatedValue:Array(count:128, repeatedValue:Float()))
    var matrixA = Array(count:61, repeatedValue:Array(count:14, repeatedValue:Float()))
    var matrixB = Array(count:61, repeatedValue:Array(count:4, repeatedValue:Float()))
    var target:[Float] = []
    var signal : [Float] = []
    var mean : [Float] = [ 14.8240505 ,-5.3120379 , 2.6904939 ,-2.4391569,  0.6064820, -1.1383287,  0.4069109 ,-0.6083701 ,-1.7883503 , 4.7825634, 7.0456514 ,-2.4444793 , 2.1157496]
    var desviation: [Float] = [9.4939708, 3.2552495, 2.0275592 ,1.3791479 ,1.1174973, 0.8679833 ,0.7787189, 0.8352188, 0.6883832 ,1.1566716, 1.5348829,0.9575440 ,0.9811263]
    var mirror : [Float] = []
    var dummy = Array(count:99,repeatedValue:Float(0))
    var sample : Int = 0
    var rate: Int = 88200
    var samRate: Int = 0
    var sizeR: Int = 0
    var iteration: Int = 0
    var NumColumns: Int = 0
    let fft_weights: FFTSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(256))), FFTRadix(kFFTRadix2))
    var result = Array(count:256,repeatedValue:Float(0))
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
        for k in 0...255{
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
        self.matrix = Array<Array<Float>>()
        self.target = []
        self.sample = 0
        self.samRate = 0
        self.sizeR = 0
        self.iteration = 0
        self.NumColumns = 0
        signal = array1 + Array(count:101040,repeatedValue:Float(0))
        length()
    }
    
// Funcion que corta la onda en frames, usando 50% de overlapping.
    func overlapping(){
        samRate = (sample/rate)*1000
        sizeR = samRate/20
        iteration = sample/sizeR - 1
        NumColumns = (3/2)*(sample/sizeR)
        
        for _ in 0...NumColumns {
                matrix.append(Array(count:157, repeatedValue:Float()))
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
            energy[i] = fft(matrix[i])
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
        for k in 0...(256-1){
            var suma:Float = 0.0
            for m in 0...(1850-1){
                suma = suma + energy[m][k]/256
            }
            result[k] = suma
        }
        
    }
    
    func log10(val: Float) -> Float {
        return log(val)/log(10.0)
    }
    
    func ft(a: [Float])->[Float]{
        var arr2:[Float] = []
        arr2.append(0.0)
        for i in 0...(a.count-2){
            arr2.append(a[i])
        }
        var arr3 = Array(count:176400,repeatedValue:Float(0))
        vDSP_conv(arr2,1,[0.95],1,&arr3,1,176400,1)
        var r:[Float] = []
        for i in 0...(a.count-1){
            var c:Float = 0.0
            c = a[i]-arr3[(176399-i)]
            r.append(c)
        }
        
        return r
    }

    
    func inverseDCT(){
        var result: Float = 0.0
        
        for i in 0...25{
            result = cosa[0]/2
            for k in 1...25{
                result = result + cosa[k]*cosf((pi/12)*Float(k)*(Float(i)+1/2))
            }
            target.append(result)
            result = 0.0
        }
    }
    
    func standarization(){
        for k in 0...12{
            target[k] = (target[k] - mean[k])/desviation[k]
        }
    }
    
    func final() -> [Float] {
        //Creo un nuevo arreglo con los primeros 13 elementos de target y un 1 al final
        var array:[Float] = []
        for i in 0...12{
            array.append(target[i])
        }
        array.append(Float(1))
        //Pasamos la matrixA a un arreglo
        var MA:[Float]=[]
        for i in matrixA{
            for j in i{
                MA.append(j)
            }
        }
        //Pasamos la matrixB a un arreglo
        var MB:[Float]=[]
        for i in matrixB{
            for j in i{
                MB.append(j)
            }
        }
        
        //Transponemos la matrixB
        var mbt = [Float](count : MA.count, repeatedValue : 0.0)
        vDSP_mtrans(MA, 1, &mbt, 1, 61, 14)
        //Realizo el producto cruz entre el arreglo creado y la matrixA
        var resultado = [Float](count : 61, repeatedValue : 0.0)
        vDSP_mmul(array, 1, mbt, 1, &resultado, 1, 1, 61, 14)
        for k in 0...60{
            resultado[k] = 1/(1+exp(-resultado[k]))
        }

        //Realizo el producto cruz entre el arreglo resultado y la matrixB traspuesta
        var resultado2 = [Float](count : 4, repeatedValue : 0.0)
        vDSP_mmul(resultado, 1, MB, 1, &resultado2, 1, 1, 4, 61)

        return resultado2
    }
}