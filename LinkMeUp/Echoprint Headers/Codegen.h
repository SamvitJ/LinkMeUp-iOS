//
//  echoprint-codegen
//  Copyright 2011 The Echo Nest Corporation. All rights reserved.
//


#ifndef CODEGEN_H
#define CODEGEN_H

// Entry point for generating codes from PCM data.
#define VERSION 4.10

#include <Foundation/Foundation.h>



using namespace std;


class  Codegen {
public:
    Codegen(const float* pcm, unsigned int numSamples, int start_offset);

    string getCodeString(){return _CodeString;}
    int getNumCodes(){return _NumCodes;}
    float getVersion() { return VERSION; }
    
    static NSString* encode(const float* pcm, unsigned int numSamples, int start_offset);
private:

    string _CodeString;
    int _NumCodes;
};

#endif
