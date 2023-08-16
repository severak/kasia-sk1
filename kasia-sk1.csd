<Cabbage>
form caption("KASIA SK1") size(400, 300), colour(51, 51, 51), guiMode("queue"), pluginId("ksk1")
keyboard bounds(8, 158, 381, 95)
checkbox bounds(278, 12, 100, 30) channel("rec") text("RECORD") colour:1(255, 0, 0, 255) colour:0(118, 0, 0, 255) 
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

; RAM filled with zeros
giRAM  ftgen 0, 0, 2*sr, 2, 0

;instrument will be triggered by keyboard widget
instr 1
    kbnd pchbend 0, 100
    kcps = p4 + kbnd
    kvel = p5

    kEnv madsr .1, .2, .6, .4
    ;aOut vco2 p5, p4
    giTableLen ftlen giRAM
    aPhs line        0,(giTableLen/sr) * (cpsmidinn(60)/p4),1
    aOut tablei      aPhs, giRAM, 1
    outs aOut*kEnv, aOut*kEnv
endin

gkRecDur    init    0
giTableLen init 0

instr GUI ; checks controls panel
    prints "SR = %d\n", sr
    giTableLen ftlen giRAM
    
    kRec, kRecTrig cabbageGetValue "rec"
    if kRecTrig==1 && kRec==1 then
        printks "REC!\n", 1
        event "i", "Record", 0, 3
        event "i", "beep", 3, 0.5
    endif
    
endin



instr beep ; played out when sampling stops
    aOut vco2 0.3, 440, 12
    outs aOut, aOut
    prints "gkRecDur = %d\n", gkRecDur
endin


; this does sampling itself
instr    Record 
    ;if    gkPause=1    goto SKIP_RECORD        ;IF PAUSE BUTTON IS ACTIVATED TEMPORARILY SKIP RECORDING PROCESS

        ainL,ainR    ins                    ;READ AUDIO FROM LIVE INPUT CHANNEL 1
        aRecNdx    line        0,giTableLen/sr,1    ;CREATE A POINTER FOR WRITING TO TABLE - FREQUENCY OF POINTER IS DEPENDENT UPON TABLE LENGTH AND SAMPLE RATE
        aRecNdx    =        aRecNdx*giTableLen    ;RESCALE POINTER ACCORDING TO LENGTH OF FUNCTION TABLE 
        gkRecDur    downsamp    aRecNdx            ;CREATE A K-RATE GLOBAL VARIABLE THAT WILL BE USED BY THE 'PLAYBACK' INSTRUMENT TO DETERMINE THE LENGTH OF RECORDED DATA            
              tablew        ainL,  aRecNdx, giRAM;WRITE AUDIO TO AUDIO STORAGE TABLE
        ;      tablew        ainR*gkInGain,  aRecNdx, gistorageR;WRITE AUDIO TO AUDIO STORAGE TABLE
        if    gkRecDur>=giTableLen    then            ;IF MAXIMUM RECORD TIME IS REACHED...
            kRecord=0
            printks "REC END\n", 1
            printks "gkRecDur = %d", 1, gkRecDur
        endif                        ;END OF CONDITIONAL BRANCH
        
        if changed(release())==1 && release()==1 then
            printks "OUT\n", 1
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
