//
//  WaveSynthAUViewController.m
//  AUInstrument
//
//  Created by Eric on 4/23/16.
//  Copyright © 2016 Eric George. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "WaveSynthAUViewController.h"
#import "WaveSynthAU.h"
#import "WaveSynthConstants.h"

static NSArray *_waveformNames;

@interface WaveSynthAUViewController ()
{
    __weak IBOutlet NSTextField *_waveformLabel;
    __weak IBOutlet NSButton *_waveformButton;
    __weak IBOutlet NSSlider *_volumeSlider;
    
    AUParameter *_volumeParameter;
    AUParameter *_waveformParameter;
    AUParameterObserverToken *_parameterObserverToken;
}

@end

@implementation WaveSynthAUViewController

-(void)setAudioUnit:(WaveSynthAU *)audioUnit
{
    _audioUnit = audioUnit;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isViewLoaded]) {
            [self connectViewWithAU];
        }
    });
}

-(WaveSynthAU *)getAudioUnit
{
    return _audioUnit;
}

- (void) connectViewWithAU
{
    AUParameterTree *parameterTree = self.audioUnit.parameterTree;
    
    if (parameterTree)
    {
        _volumeParameter = [parameterTree valueForKey:@"volume"];
        _waveformParameter = [parameterTree valueForKey:@"waveform"];
        
        _parameterObserverToken = [parameterTree tokenByAddingParameterObserver:^(AUParameterAddress address, AUValue value) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (address == self->_volumeParameter.address)
                {
                    [self updateVolume];
                }
                else if (address == self->_waveformParameter.address)
                {
                    [self updateWaveform];
                }
                
            });
        }];
        
        [self updateVolume];
    }

    [self updateVolume];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[_waveformButton layer] setBorderWidth:1.0f];
    [[_waveformButton layer] setBorderColor:[NSColor blackColor].CGColor];
    
    if (_audioUnit)
    {
        [self connectViewWithAU];
    }

    _waveformNames = @[@"Sine", @"Sawtooth", @"Square", @"Triangle"];
    
    OscillatorWave waveform = self.audioUnit.selectedWaveform;
    _waveformLabel.stringValue = _waveformNames[waveform];
}

- (void) updateVolume
{
    _volumeSlider.floatValue = _volumeParameter.value;
}

- (IBAction)volumeChanged:(NSSlider *)sender
{
    _volumeParameter.value =  sender.floatValue;
}

- (void) updateWaveform
{
    OscillatorWave waveform = self.audioUnit.selectedWaveform;
    _waveformLabel.stringValue = _waveformNames[waveform];
}

- (IBAction)waveformChanged:(id)sender
{
    OscillatorWave waveform = self.audioUnit.selectedWaveform;
    if (waveform == OSCILLATOR_WAVE_LAST)
    {
        waveform = OSCILLATOR_WAVE_FIRST;
    }
    else
    {
        ++waveform;
    }
    
    self.audioUnit.selectedWaveform = waveform;
    _waveformLabel.stringValue = _waveformNames[waveform];
}

@end



@implementation WaveSynthAUViewController (AUAudioUnitFactory)

- (WaveSynthAU *) createAudioUnitWithComponentDescription:(AudioComponentDescription) desc error:(NSError **)error
{
    self.audioUnit = [[WaveSynthAU alloc] initWithComponentDescription:desc error:error];
    return self.audioUnit;
}

@end
