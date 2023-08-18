<Cabbage>
form caption("KASIA SK1") size(400, 300), colour(51, 51, 51), guiMode("queue"), pluginId("ksk1")
keyboard bounds(8, 196, 381, 95) channel("keyboard2") value(48)
checkbox bounds(124, 80, 100, 30) channel("rec") text("RECORD") colour:1(255, 0, 0, 255) colour:0(118, 0, 0, 255) 

label bounds(8, 8, 230, 42) channel("label10002") text("KASIA SK1")
label bounds(240, 12, 154, 16) channel("label10003") text("sampling keyboard")
checkbox bounds(10, 148, 80, 20) channel("loop") text("LOOP")
combobox bounds(10, 124, 80, 20) channel("envelope") text("piano-like", "organ-like", "string-like", "flute-like", "slow flute") value(1)
filebutton bounds(144, 116, 80, 30) channel("open") , populate("*.wav", ".", "0")
filebutton bounds(144, 154, 80, 30) channel("save") text("Save file", "Save file"), mode("save"), populate("*.wav", ".", "0")
combobox bounds(10, 80, 80, 20) channel("tone") value(1) text("piano", "trumpet", "choir", "pipe organ", "brass ensemble", "flute", "synth drum", "jazz organ", "SAMPLE")
label bounds(10, 54, 80, 18) channel("label10009") text("TONE")
label bounds(10, 102, 80, 18) channel("label10010") text("ENV")
label bounds(143, 53, 80, 20) channel("label10011") text("SAMPLE")

checkbox bounds(10, 170, 80, 20) channel("lofi") text("LOFI")
label bounds(260, 54, 100, 20) channel("label10013") text("SYNTH")
label bounds(257, 120, 117, 16) channel("label10014") text("coming soon™")
label bounds(240, 32, 154, 16) channel("label10015") text("(by Severák)")
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
ksmps = 32
nchnls = 2
0dbfs = 1

opcode  LoFi,a,akk
    ain,kbits,kfold xin                                 ; READ IN INPUT ARGUMENTS
    kvalues pow     2, kbits                            ; RAISES 2 TO THE POWER OF kbitdepth. THE OUTPUT VALUE REPRESENTS THE NUMBER OF POSSIBLE VALUES AT THAT PARTICULAR BIT DEPTH
    aout    =       (int((ain/0dbfs)*kvalues))/kvalues  ; BIT DEPTH REDUCE AUDIO SIGNAL
    aout    fold    aout, kfold                         ; APPLY SAMPLING RATE FOLDOVER
    xout    aout                                ; SEND AUDIO BACK TO CALLER INSTRUMENT
endop

; RAM filled with zeros
giRAM  ftgen 0, 0, 2*sr, 2, 0
giRAM_OG = giRAM

giWaves[] init 10

giWaves[1] ftgen 0, 0, 0, 1, "presets/piano.wav", 0, 0, 0
giWaves[2] ftgen 0, 0, 0, 1, "presets/trumpet.wav", 0, 0, 0
giWaves[3] ftgen 0, 0, 0, 1, "presets/choir.wav", 0, 0, 0
giWaves[4] ftgen 0, 0, 0, 1, "presets/pipe.wav", 0, 0, 0
giWaves[5] ftgen 0, 0, 0, 1, "presets/brass.wav", 0, 0, 0
giWaves[6] ftgen 0, 0, 0, 1, "presets/flute.wav", 0, 0, 0
giWaves[7] ftgen 0, 0, 0, 1, "presets/tom.wav", 0, 0, 0
giWaves[8] ftgen 0, 0, 0, 1, "presets/jazz.wav", 0, 0, 0
giWaves[9] = giRAM_OG

giEnvs[] init 10
giEnvs[1] = 1
giEnvs[2] = 1
giEnvs[3] = 4
giEnvs[4] = 2
giEnvs[5] = 1
giEnvs[6] = 4
giEnvs[7] = 1
giEnvs[8] = 2
giEnvs[9] = 2

gSfilepath    init    ""

;instrument will be triggered by keyboard widget
instr 1
    iloop chnget "loop"
    kbnd pchbend 0, 100
    kcps = p4 + kbnd
    kvel = p5

    ia_envelope chnget "envelope"
    itone chnget "tone"
    ilofi chnget "lofi"
    
    if ia_envelope == 1 then
        ; piano-like
        kEnv madsr 0.05, 2, 0, 0.2
        ;kEnv = kEnv * kvel
    elseif ia_envelope == 2 then
        ; organ-like
        kEnv madsr 0.05, 0.01, 1, 0.05
    elseif ia_envelope == 3 then
        ; string-like
        kEnv madsr 0.05, 1, 0, 1
        ;kEnv = kEnv * kvel
    elseif ia_envelope == 4 then
        ; flute-like
        kEnv madsr 0.2, 0.1, 0.8, 0.4
    elseif ia_envelope == 5 then
        ; slow-flute-like
        kEnv madsr 0.5, 0.4, 0.6, 0.6    
    endif
    
    if iloop==1 then
        aOut flooper2 1, kcps/(cpsmidinn(60)), 0.3, 2, 0.25, giWaves[itone]
    else
        iTableLen ftlen giWaves[itone]
        aPhs line        0,(iTableLen/sr) * ((cpsmidinn(60))/p4),1
        aOut tablei      aPhs, giWaves[itone], 1
        
        ; printks "L = %02f\n", 0.1, k(aPhs)
        if k(aPhs)>1 then
            turnoff
        endif
    endif
    
    aOut = aOut*kEnv
    
    if ilofi==1 then
        aOut LoFi aOut, 8, 4
    endif
    
    outs aOut*0.5, aOut*0.5
endin

gkRecDur    init    0
giTableLen init 0

instr GUI ; checks controls panel
    prints "SR = %d\n", sr
    giTableLen ftlen giRAM
    
    kRec, kRecTrig cabbageGetValue "rec"
    if kRecTrig==1 && kRec==1 then
        event "i", "waiting", 0, 10
    endif
    
    gSfilepath    chnget    "open"
    kNewFileTrg    changed    gSfilepath        ; if a new file is loaded generate a trigger
    if kNewFileTrg==1 then                    ; if a new file has been loaded...
        event    "i",99,0,0                        ; call instrument to update sample storage function table 
        printks "LOAD = %s\n", 0, gSfilepath
    endif
    
    Ssavepath chnget "save"
    kSaveTrig changed Ssavepath
    if kSaveTrig==1 then
        printks "SAVE = %s\n", 0, Ssavepath
        kans ftaudio kSaveTrig, giRAM, Ssavepath, 6
    endif
    
    kTone chnget "tone"
    kToneTrig changed kTone
    if kToneTrig==1 then
        printks "kEnv = %d\n", 0, giEnvs[kTone]
        kEnvType = giEnvs[kTone]
        cabbageSetValue "envelope", kEnvType
    endif
endin

instr beep ; played out when sampling stops
    cabbageSetValue "rec", 0
    cabbageSetValue "tone", 9, release()
    aOut vco2 0.3, 440, 12
    kEnv linen 1, 0.1, 0.5, 0.1
    outs aOut*kEnv, aOut*kEnv
    prints "gkRecDur = %d\n", gkRecDur
endin

instr beep2 ; played out when sampling stops
    cabbageSetValue "rec", 0
    aOut vco2 0.3, 220, 0
    kEnv linen 1, 0.1, 0.5, 0.1
    outs aOut*kEnv, aOut*kEnv
    prints "gkRecDur = %d\n", gkRecDur
endin

instr    99    ; load sound file
 gichans    filenchnls    gSfilepath            ; derive the number of channels (mono=1,stereo=2) in the sound file
 giRAM    ftgen    1,0,0,1,gSfilepath,0,0,1
 giWaves[9] = giRAM
 ;giFileSamps    =        nsamp(gitableL)            ; derive the file duration in samples
 ;giFileLen    filelen        gSfilepath            ; derive the file duration in seconds
 ;gkTabLen    init        ftlen(gitableL)            ; table length in sample frames
 ;if gichans==2 then
 ; gitableR    ftgen    2,0,0,1,gSfilepath,0,0,2
 ;endif
 ;giReady     =    1                    ; if no string has yet been loaded giReady will be zero
 ;Smessage sprintfk "file(%s)", gSfilepath            ; print file to viewer
 ;chnset Smessage, "filer1"    

 /* WRITE FILE NAME TO GUI */
 ;Sname FileNameFromPath    gSfilepath                ; Call UDO to extract file name from the full path
 ;Smessage sprintfk "text(%s)",Sname
 ;chnset Smessage, "stringbox"

endin

; from http://floss.booktype.pro/csound/l-amplitude-and-pitch-tracking/
instr waiting
 iThreshold =    0.02                 ; rms threshold
 aSig, aSigB ins
 kRms    rms     aSig                ; scan rms
 ;aRms    follow    aSig, 0.01
 kTrig   =       kRms > iThreshold ? 1 : 0  ; gate either 1 or zero
 kTriggered init 0
 printks "RMS = %02f\n", 0.1, kRms
 
 if changed(kTrig)==1 && kTrig==1 then
    event "i", "Record", 0, 2
    event "i", "beep", 2.1, 0.5
    kTriggered = 1
    turnoff
 endif
 
 if release()==1 && kTriggered==0 then
    event "i", "beep2", 0, .5
 endif
endin



; this does sampling itself
instr    Record
    giRAM = giRAM_OG
    giWaves[9] = giRAM_OG
    ;if    gkPause=1    goto SKIP_RECORD        ;IF PAUSE BUTTON IS ACTIVATED TEMPORARILY SKIP RECORDING PROCESS

        ainL,ainR    ins                    ;READ AUDIO FROM LIVE INPUT CHANNEL 1
        ;ainL LoFi ainL, 8, 1
        aRecNdx    line        0,giTableLen/sr,1    ;CREATE A POINTER FOR WRITING TO TABLE - FREQUENCY OF POINTER IS DEPENDENT UPON TABLE LENGTH AND SAMPLE RATE
        aRecNdx    =        aRecNdx*giTableLen    ;RESCALE POINTER ACCORDING TO LENGTH OF FUNCTION TABLE 
        gkRecDur    downsamp    aRecNdx            ;CREATE A K-RATE GLOBAL VARIABLE THAT WILL BE USED BY THE 'PLAYBACK' INSTRUMENT TO DETERMINE THE LENGTH OF RECORDED DATA            
              tablew        ainL,  aRecNdx, giRAM;WRITE AUDIO TO AUDIO STORAGE TABLE
        ;      tablew        ainR*gkInGain,  aRecNdx, gistorageR;WRITE AUDIO TO AUDIO STORAGE TABLE
        if    gkRecDur>=giTableLen    then            ;IF MAXIMUM RECORD TIME IS REACHED...
        ;    kRecord=0
            printks "REC END\n", 1
            printks "gkRecDur = %d", 1, gkRecDur
        ;endif                        ;END OF CONDITIONAL BRANCH
        
        ;if changed(release())==1 && release()==1 then
        
        ;if k(aRecNdx)==giTableLen then
        
            printks "OUT\n", 1
            ;event "i", "beep", 0.1, 0.5
            ;cabbageSetValue "rec", 0
        endif
    ;SKIP_RECORD:
endin



</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
f0 z

i "GUI"  0 z 

</CsScore>
</CsoundSynthesizer>
