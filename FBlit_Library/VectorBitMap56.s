

*-----------------------------------------------------------------------------
*
*	VectorBitMap56.s
*
*	© Stephen Brookes 1998-2000
*
*	Render clipped vector to bitmap
*
*-----------------------------------------------------------------------------

	machine MC68030




	;
	;VectorBitMap	(render vector section to bitmap)
	;
	;<a0- *BitMap
	; d0- aX.w:aY.w 	(vector (note: these may be -ve!))
	; d1- bX.w:bY.w
	; d2- MinX.w:MinY.w	(clip Rectangle (must be +ve))
	; d3- MaxX.w:MaxY.w
	; d4- Pen0.b|Pen1.b:Mask.b|Flags.b
	; d5- Pttrn.w:PatCnt.w
	;
	;>
	;all reg's preserved
	;
	;flags-	none(JAM1)	(pttrn 1s set to pen1)
	;	FB_JAM2		(pttrn 1s set to pen1, pttrn 0s set to pen0)
	;	FB_COMPLEMENT	(pttrn 1s complement dest)
	;	FB_INVERSVID	(combines with previous and inverts pttrn)
	;



VBM_YDIRECTION		EQU		7			;y direction
VBM_REVERSE		EQU		6			;render direction is reversed
VBM_HORIZONTAL		EQU		5			;horizontal


VectorBitMap:
		movem.l 	d0-d7/a0-a6,-(sp)

SPACE			EQU		$34
		
		sub.l		#SPACE,sp			;space
		
FLAG			EQU		0
FIRST			EQU		4			;first slice
LAST			EQU		8			;last slice
RUN			EQU		$c			;run slice
ERROR			EQU		$10			;error
FRACTION		EQU		$14			;fraction
SLICES			EQU		$18			;mid slices
INITCLIP		EQU		$1c			;initial pixels clipped
ENDCLIP			EQU		$20			;end pixels clipped
TOTALPIX		EQU		$24			;total #pixels
STARTX			EQU		$28			;startx (clipped)
STARTY			EQU		$2c			;starty (clipped)
TEMP			EQU		$30


		clr.l		(FLAG,sp)

	;set up vector
	
	;make vector go right

		cmp.l		d0,d1
		bge.s		VBMs0				;--> bx>=ax

		exg		d0,d1
		bset		#VBM_REVERSE,(FLAG,sp)
		
	;make deltas
VBMs0:
		move.l		d0,d6				;d6- ax:ay
		move.l		d1,d7				;d7- bx:by
		move.l		d0,a0				;a0- ax:ay
		move.l		d1,a1				;a1- bx:by
		
		moveq.l		#$00,d4				;d4- initital clip
		moveq.l		#$00,d5				;d5- end clip
		
		sub.w		d0,d1				;d1- bx:ydelta
		move.w		d1,d0				;d0- ax:ydelta
		sub.l		d0,d1				;d1- xdelta:0

	;make ydelta +ve and clip in y
		
		tst.w		d0
		bpl.s		VBMs1				;--> +ve y
		
		exg.l		d6,d7				;swap ay/by
VBMs1:		
		cmp.w		d2,d7
		blt		VBMx				;--> by<miny, exit (or ay<miny for -ve)
		
		cmp.w		d3,d6			
		bgt		VBMx				;--> ay>maxy, exit (or by>maxy for -ve)
		
		sub.w		d6,d2
		bmi.s		VBMCYs0				;--> ay>miny, no init clip (or by>miny
								;	for -ve, no end clip)
		move.w		d2,d4
VBMCYs0:		
		sub.w		d3,d7
		bmi.s		VBMCYs1				;--> by<maxy, no end clip (or ay<maxy
								;	for -ve, no init clip)		
		move.w		d7,d5
VBMCYs1:
		tst.w		d0
		bpl.s		VBMClipX			;--> +ve y

		bset		#VBM_YDIRECTION,(FLAG,sp)		
		neg.w		d0				;+ve ydelta
		exg.l		d6,d7				;swap ay/by
		exg.l		d4,d5				;d4- initclip, d5- endclip		
		
	;clip in x
	
VBMClipX:
		swap		d2				;d2- ****:minx
		swap		d3				;d3- ****:maxx
		swap		d6				;d6- ****:ax
		swap		d7				;d7- ****:bx

		cmp.w		d2,d7
		blt		VBMx				;--> bx<minx, exit

		cmp.w		d3,d6
		bgt		VBMx				;--> ax>maxx, exit
		
		sub.w		d3,d7
		bmi.s		VBMCXs0				;--> bx<maxx
		
		cmp.w		d7,d5
		bcc.s		VBMCXs0				;--> new clip < current
		
		move.w		d7,d5
VBMCXs0:	
		sub.w		d6,d2
		bmi.s		VBMHoriz			;--> ax>minx
		
		cmp.w		d2,d4
		bcc.s		VBMHoriz			;--> new clip < current
		
		move.w		d2,d4
		
	;set up more vector stuff
	
VBMHoriz:			
		swap		d1				;d1- xdelta
		and.l		#$ffff,d0			;d0- ydelta
		cmp.w		d1,d0
		bcc.s		VBMVert				;--> vertical set up
		
		exg		d0,d1
		bset		#VBM_HORIZONTAL,(FLAG,sp)
VBMVert:		
		moveq.l		#$01,d3
		move.l		d4,(INITCLIP,sp)		;set initial clip #pixels
		add.w		d0,d3				;d3- #pixels total
		move.l		d3,(TOTALPIX,sp)
		sub.w		d4,d3				;    - initial clip
		move.l		d5,(ENDCLIP,sp)
		sub.w		d5,d3				;    - end clip
		bls		VBMx				;--> totaly clipped(!?)

		tst.w		d1
		bne.s		VBMVs0				;--> not flat
		
		addq.l		#$01,d0
		move.l		d0,(FIRST,sp)
		clr.l		(LAST,sp)
		clr.l		(SLICES,sp)
		bra		VBMStartClip			;--> done
VBMVs0:
		divu.w		d1,d0				;d0- ydelta/xdelta (r:q)
		move.l		d0,d6
		clr.w		d6
		and.l		#$ffff,d0			;d0- run slice
		swap		d6				;d6- remainder
		beq.s		VBMVs0a				;--> no remainder
		
	;	moveq		#$00,d7
	;	divu.l		d1,d6:d7			;d7- (remainder*2^32)/xdelta (frac)
	;	move.l		d7,d6
	
	swap		d6
	divu.l		d1,d6
	swap		d6
	
VBMVs0a:		
		move.l		d0,(RUN,sp)			;run slice
		
		lsr.l		#$02,d6
		move.l		d6,(FRACTION,sp)		;fraction
		move.l		d6,d7				;d7- fraction
		
		lsr.l		#$01,d6
		sub.l		#$40000000,d6			;d6- error (fraction/2 - 1)
		
		lsr.l		#$01,d0
		bcc.s		VBMVs1				;--> runslice is even
		
		add.l		#$20000000,d6			;error + 0.5
		bra.s		VBMVs2				;--> runslice is odd
VBMVs1:		
		tst.l		d7
		bne.s		VBMVs2				;--> fraction>0
		
		move.l		d0,(FIRST,sp)			;first = runslice/2
		addq.l		#$01,d0
		bra.s		VBMVs3				;--> continue
VBMVs2:
		addq.l		#$01,d0
		move.l		d0,(FIRST,sp)			;first = runslice/2 + 1
VBMVs3:				
		move.l		d0,(LAST,sp)			;last slice
		move.l		d6,(ERROR,sp)			;error
		
		subq.l		#$01,d1
		bpl.s		VBMVs4				;--> some slices
		
		moveq		#$00,d1			
VBMVs4:		
		move.l		d1,(SLICES,sp)			;#mid slices
	
	;this is a 'quick' fix attempt at making lines more 'blitter' like (ok, not very quick really)
	
		btst		#VBM_REVERSE,(FLAG,sp)
		beq.s		VBMStartClip			;--> going the right way
		
	;the algorithm always produces a longer last slice, which is fine, so does the blitter, but
	;if we are rendering in reverse, our 'last' slice would be the blitters 'first' slice, and so
	;should be short. This is simply fixed by swapping last<->first, so our first becomes long.
	;However, for better results, we also need to modify the initial error value to try and ensure
	;that the (long/short) slice sequence is also reversed (without breaking accuracy).. yuch.
	;
	;d0- last
	;d1- slices
	;d6- error
		
		tst.l		d0
		beq.s		VBMStartClip			;--> nothing to do
	
		move.l		(FRACTION,sp),d4
		bra.s		VBMVs5				;enter loop
VBMVl0:		
		add.l		d4,d6				;update error
		bmi.s		VBMVs5				;--> no overflow
		
		sub.l		#$40000000,d6			;reset error
VBMVs5:
		dbra		d1,VBMVl0

		move.l		#$bfffffff,d2			;d2- '-1' (more or less, in fact '-1'
								;    itself causes some innaccuracy)
		sub.l		d6,d2				;d2- -1 - error (also -ve)
		move.l		d2,(ERROR,sp)
		
		move.l		(FIRST,sp),d1
		move.l		d0,(FIRST,sp)
		move.l		d1,(LAST,sp)
		
		
	;more clipping (note: a0,a1 contain true vector start/end coordinates (local/unclipped))
	
	;!!!Note: a0/a1 contain the vector effected by VBM_REVERSE ie. start/end as it will be rendered,
	;rather than as provided to this function!!!
	
	;err, yes, well I can't be bothered with this just now, so here we go with the *huge* and
	;horrible mega clipping nonsense...
	
	;
	;find the start point (maybe there isn't one!!)
	;
	
VBMStartClip:
		moveq		#$00,d1
		move.l		a0,d0				;d0- ax:ay
		move.w		d0,d1				;d1- ay
		clr.w		d0
		swap		d0				;d0- ax
		ext.l		d1				;** these are signed!!
		ext.l		d0
		move.l		d1,(STARTY,sp)
		move.l		d0,(STARTX,sp)
		
		tst.l		(INITCLIP,sp)
		beq		VBMEndClip			;--> no clipping required

		moveq		#$00,d5
		move.w		(SPACE+8,sp),d5			;d5- minx
		move.l		(ERROR,sp),d4			;d4- error
		move.l		(FRACTION,sp),a2		;a2- fraction
		move.l		(RUN,sp),a3			;a3- run length
		move.l		(SLICES,sp),d7			;d7- slices

	;four routines are required!! Tending vertical and horizontal with +-Y for each (bummer)

		btst		#VBM_HORIZONTAL,(FLAG,sp)
		beq		VBMStartVert			;--> vertical
		
		btst		#VBM_YDIRECTION,(FLAG,sp)
		bne.s		VBMStartHUp			;--> -ve Y
		
		moveq		#$00,d6
		move.w		(SPACE+10,sp),d6		;d6- miny
		
	;find the relevent slice (horizontal, +veY)
	
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMStartHDMidSkip0		;--> enter loop...
VBMStartHDMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMStartHDMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMStartHDMidSkip0:
		addq.l		#$01,d1				;d1- next Y
		add.l		d2,d0				;d0- next X
		cmp.l		d1,d6
		bge.s		VBMStartHDMid			;--> miny>=Y (out of range)
		
		cmp.l		d5,d0
		bgt.s		VBMStartHDX			;--> X>minx (found slice)				
VBMStartHDMid:		
		dbra		d7,VBMStartHDMidLoop0		;--> do next y
		
	;got to the last slice.. (which means it's the only slice, hence run SLICES=0, FIRST=LAST
	;and LAST=0) (also, no coordinate testing is needed since this would have been clipped earlier)
			
		move.l		(LAST,sp),d2
		moveq		#$00,d7				;d7- there are no run SLICES
		move.l		d7,(LAST,sp)			;only one slice, and it's always FIRST
		addq.l		#$01,d1				;d1- next Y (guaranteed >miny!)
		add.l		d2,d0				;d0- next X (guaranteed >minx!)

	;found the slice.. (d0- X(slice end +1) d1- Y(+1), d2- length, d4- ERROR, d7- SLICES)
	;clip/update the line definition
	
VBMStartHDX:
		move.l		(SPACE+12,sp),d3		;d3- maxx:maxy
		subq.l		#$01,d1				;d1- starty
		cmp.w		d3,d1
		bgt		VBMx				;--> starty>maxy (game over)		
				
		swap		d3				;d3- maxy:maxx
		sub.l		d2,d0				;d0- startx
		cmp.l		d5,d0
		bgt.s		VBMStartHDXs0			;--> startx>minx
		
		add.l		d0,d2				;d2- end of slice(+1)
		move.l		d5,d0				;startx=minx
		sub.l		d5,d2				;d2- new slice length
VBMStartHDXs0:
		cmp.w		d3,d0		
		ble		VBMStartX			;--> startx<=maxx... continue
		
		bra		VBMx				;--> exit
	
	;same again, with -veY
	
VBMStartHUp:	
		moveq		#$00,d6
		move.w		(SPACE+14,sp),d6		;d6- maxy
		
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMStartHUMidSkip0		;--> enter loop...
VBMStartHUMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMStartHUMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMStartHUMidSkip0:
		subq.l		#$01,d1				;d1- next Y
		add.l		d2,d0				;d0- next X
		cmp.l		d6,d1
		bge.s		VBMStartHUMid			;--> Y>=maxy (out of range)
		
		cmp.l		d5,d0
		bgt.s		VBMStartHUX			;--> X>minx (found slice)				
VBMStartHUMid:		
		dbra		d7,VBMStartHUMidLoop0		;--> do next y
			
		move.l		(LAST,sp),d2
		moveq		#$00,d7				;d7- there are no run SLICES
		move.l		d7,(LAST,sp)			;only one slice, and it's always FIRST
		subq.l		#$01,d1				;d1- next Y (guaranteed <maxy!)
		add.l		d2,d0				;d0- next X (guaranteed >minx!)
VBMStartHUX:
		move.l		(SPACE+10,sp),d3		;d3- miny:maxx
		addq.l		#$01,d1				;d1- starty
		swap		d3				;d3- maxx:miny
		cmp.w		d1,d3
		bgt		VBMx				;--> miny>starty (game over)		
				
		swap		d3				;d3- miny:maxx
		sub.l		d2,d0				;d0- startx
		cmp.l		d5,d0
		bgt.s		VBMStartHUXs0			;--> startx>minx
		
		add.l		d0,d2				;d2- end of slice(+1)
		move.l		d5,d0				;startx=minx
		sub.l		d5,d2				;d2- new slice length
VBMStartHUXs0:
		cmp.w		d3,d0		
		ble		VBMStartX			;--> startx<=maxx... continue
		
		bra		VBMx				;--> exit
	
	;vertical +veY
	
VBMStartVert:			
		btst		#VBM_YDIRECTION,(FLAG,sp)
		bne.s		VBMStartVUp			;--> -ve Y

		moveq		#$00,d6
		move.w		(SPACE+10,sp),d6		;d6- miny
	
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMStartVDMidSkip0		;--> enter loop...
VBMStartVDMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMStartVDMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMStartVDMidSkip0:
		add.l		d2,d1				;d1- next Y
		addq.l		#$01,d0				;d0- next X
		cmp.l		d1,d6
		bge.s		VBMStartVDMid			;--> miny>=Y (out of range)
		
		cmp.l		d5,d0
		bgt.s		VBMStartVDX			;--> X>minx (found slice)				
VBMStartVDMid:		
		dbra		d7,VBMStartVDMidLoop0		;--> do next x
			
		move.l		(LAST,sp),d2
		moveq		#$00,d7				;d7- there are no run SLICES
		move.l		d7,(LAST,sp)			;only one slice, and it's always FIRST
		add.l		d2,d1				;d1- next Y (guaranteed >miny!)
		addq.l		#$01,d0				;d0- next X (guaranteed >minx!)
VBMStartVDX:
		move.l		(SPACE+12,sp),d3		;d3- maxx:maxy
		swap		d3				;d3- maxy:maxx
		subq.l		#$01,d0				;d0- startx
		cmp.w		d3,d0
		bgt		VBMx				;--> startx>maxx (game over)		
				
		swap		d3				;d3- maxx:maxy
		sub.l		d2,d1				;d1- starty
		cmp.l		d6,d1
		bgt.s		VBMStartVDXs0			;--> starty>miny
		
		add.l		d1,d2				;d2- end of slice(+1)
		move.l		d6,d1				;starty=miny
		sub.l		d6,d2				;d2- new slice length
VBMStartVDXs0:
		cmp.w		d3,d1		
		ble.s		VBMStartX			;--> starty<=maxy... continue
		
		bra		VBMx				;--> exit
	
	;same again, with -veY
	
VBMStartVUp:	
		moveq		#$00,d6
		move.w		(SPACE+14,sp),d6		;d6- maxy
	
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMStartVUMidSkip0		;--> enter loop...
VBMStartVUMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMStartVUMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMStartVUMidSkip0:
		sub.l		d2,d1				;d1- next Y
		addq.l		#$01,d0				;d0- next X
		cmp.l		d6,d1
		bge.s		VBMStartVUMid			;--> Y>=maxy (out of range)
		
		cmp.l		d5,d0
		bgt.s		VBMStartVUX			;--> X>minx (found slice)				
VBMStartVUMid:		
		dbra		d7,VBMStartVUMidLoop0		;--> do next x
			
		move.l		(LAST,sp),d2
		moveq		#$00,d7				;d7- there are no run SLICES
		move.l		d7,(LAST,sp)			;only one slice, and it's always FIRST
		sub.l		d2,d1				;d1- next Y (guaranteed <maxy!)
		addq.l		#$01,d0				;d0- next X (guaranteed >minx!)
VBMStartVUX:
		move.l		(SPACE+10,sp),d3		;d3- miny:maxx
		subq.l		#$01,d0				;d0- startx
		cmp.w		d3,d0
		bgt		VBMx				;--> startx>maxx (game over)		
				
		swap		d3				;d3- maxx:miny
		add.l		d2,d1				;d1- starty
		cmp.l		d6,d1
		ble.s		VBMStartVUXs0			;--> starty<=maxy
		
		sub.l		d2,d1				;d1- end of slice(-1)
		move.l		d6,d2				;d2- starty
		sub.l		d1,d2				;d2- new slice length
		move.l		d6,d1				;starty=maxy
VBMStartVUXs0:
		cmp.w		d3,d1
		bge.s		VBMStartX			;--> starty>=miny... continue
		
		bra		VBMx				;--> exit

	;
	;common exit code for start clip (finishes up new line definition)
	;
		
VBMStartX:		
		move.l		d7,(SLICES,sp)			;store (possibly) new #SLICES
		move.l		d2,(FIRST,sp)			;store new FIRST
		move.l		d4,(ERROR,sp)			;store (possibly) new ERROR
		
		move.l		d0,d2
		sub.l		(STARTX,sp),d2			;d2- initial x clip
		
		move.l		d1,d4				;d4- starty
		move.l		(STARTY,sp),d6			;d6- original starty
		
		btst		#VBM_YDIRECTION,(FLAG,sp)
		bne.s		VBMStartXs0			;--> -ve Y
		
		exg		d4,d6
VBMStartXs0:
		sub.l		d4,d6				;d6- initial y clip
		cmp.l		d2,d6
		bgt.s		VBMStartXs1			;--> d6>d2
		
		move.l		d2,d6
VBMStartXs1:		
		move.l		d6,(INITCLIP,sp)				
		move.l		d0,(STARTX,sp)
		move.l		d1,(STARTY,sp)				
				
		


	;
	;find the end point		
	;
						
VBMEndClip:
		tst.l		(ENDCLIP,sp)
		beq		VBMRender			;--> no end clip		
		
	;two things are guaranteed at this point...
	;a) STARTX/Y are within range (and therefore +ve)
	;b) the line ends with either (or both)	X/Y out of range
	
		moveq		#$00,d5
		move.w		(SPACE+12,sp),d5		;d5- maxx
		move.l		(ERROR,sp),d4			;d4- error
		move.l		(FRACTION,sp),a2		;a2- fraction
		move.l		(RUN,sp),a3			;a3- run length
		move.l		(SLICES,sp),d7			;d7- slices

	;four routines are required (again)!! Tending vertical and horizontal with +-Y for each

		btst		#VBM_HORIZONTAL,(FLAG,sp)
		beq		VBMEndVert			;--> vertical
		
		btst		#VBM_YDIRECTION,(FLAG,sp)
		bne.s		VBMEndHUp			;--> -ve Y
		
		moveq		#$00,d6
		move.w		(SPACE+14,sp),d6		;d6- maxy
		
	;find the relevent slice (horizontal, +veY)
	
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMEndHDMidSkip0		;--> enter loop
VBMEndHDMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMEndHDMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMEndHDMidSkip0:
		addq.l		#$01,d1				;d1- next Y
		add.l		d2,d0				;d0- next X
		cmp.l		d6,d1
		bgt.s		VBMEndHDX			;--> Y>maxy (found slice)
		
		cmp.l		d5,d0
		bgt.s		VBMEndHDX			;--> X>maxx (found slice)				
VBMEndHDMid:		
		dbra		d7,VBMEndHDMidLoop0		;--> do next y
		
	;got to the last slice.. (which means, this must contain the clip)
		
		move.l		(LAST,sp),d2
		addq.l		#$01,d1				;d1- next Y (a bit redundant, but may
								;    be needed later if I want more info)
		add.l		d2,d0				;d0- next X

	;found the slice.. (d0- X(slice end +1), d1- Y(+1), d2- length, d5- maxx, d7- SLICES)
	;final clipping
		
VBMEndHDX:
		subq.l		#$01,d0				;d0- last X of this slice
		subq.l		#$01,d1				;d1- last Y
		move.l		d0,d4
		sub.l		d5,d4				;d4- X-maxx
		blt		VBMEndX				;--> maxx>X, so length already accurate
		
		sub.l		d4,d2				;d2- new slice length
		move.l		d5,d0				;d0- last X (=maxx)
		bra		VBMEndX				;--> get on with it :/
		
	;same again for -ve Y
			
VBMEndHUp:				
		moveq		#$00,d6
		move.w		(SPACE+10,sp),d6		;d6- miny
		
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMEndHUMidSkip0		;--> enter loop
VBMEndHUMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMEndHUMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMEndHUMidSkip0:
		subq.l		#$01,d1				;d1- next Y
		add.l		d2,d0				;d0- next X
		cmp.l		d1,d6
		bgt.s		VBMEndHUX			;--> miny>Y (found slice)
		
		cmp.l		d5,d0
		bgt.s		VBMEndHUX			;--> X>maxx (found slice)				
VBMEndHUMid:		
		dbra		d7,VBMEndHUMidLoop0		;--> do next y
		
		move.l		(LAST,sp),d2
		subq.l		#$01,d1				;d1- next Y (a bit redundant, but may
								;    be needed later if I want more info)
		add.l		d2,d0				;d0- next X
VBMEndHUX:
		subq.l		#$01,d0				;d0- last X of this slice
		addq.l		#$01,d1				;d1- last Y
		move.l		d0,d4
		sub.l		d5,d4				;d4- X-maxx
		blt		VBMEndX				;--> maxx>X, so length already accurate
		
		sub.l		d4,d2				;d2- new slice length
		move.l		d5,d0				;d0- last X (=maxx)
		bra		VBMEndX				;--> get on with it :/

	;same for vertical
VBMEndVert			
		btst		#VBM_YDIRECTION,(FLAG,sp)
		bne.s		VBMEndVUp			;--> -ve Y
		
		moveq		#$00,d6
		move.w		(SPACE+14,sp),d6		;d6- maxy
		
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMEndVDMidSkip0		;--> enter loop
VBMEndVDMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMEndVDMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMEndVDMidSkip0:
		add.l		d2,d1				;d1- next Y
		addq.l		#$01,d0				;d0- next X
		cmp.l		d6,d1
		bgt.s		VBMEndVDX			;--> Y>maxy (found slice)
		
		cmp.l		d5,d0
		bgt.s		VBMEndVDX			;--> X>maxx (found slice)				
VBMEndVDMid:		
		dbra		d7,VBMEndVDMidLoop0		;--> do next x
		
		move.l		(LAST,sp),d2
		addq.l		#$01,d0				;d0- next X (a bit redundant, but may
								;    be needed later if I want more info)
		add.l		d2,d1				;d1- next Y
VBMEndVDX:
		subq.l		#$01,d0				;d0- last X
		subq.l		#$01,d1				;d1- last Y (of slice)
		move.l		d1,d4
		sub.l		d6,d4				;d4- Y-maxy
		blt.s		VBMEndX				;--> maxy>Y, so length already accurate
		
		sub.l		d4,d2				;d2- new slice length
		move.l		d6,d1				;d0- last Y (=maxy)
		bra.s		VBMEndX				;--> get on with it :/
		
	;same again for -ve Y
			
VBMEndVUp:				
		moveq		#$00,d6
		move.w		(SPACE+10,sp),d6		;d6- miny
		
		move.l		(FIRST,sp),d2			;d2- start slice length
		bra.s		VBMEndVUMidSkip0		;--> enter loop
VBMEndVUMidLoop0:
		move.l		a3,d2				;d2- run slice length
		add.l		a2,d4				;update error
		bmi.s		VBMEndVUMidSkip0		;--> no overflow
		
		addq.l		#$01,d2				;d2- long slice
		sub.l		#$40000000,d4			;reset error		
VBMEndVUMidSkip0:
		addq.l		#$01,d0				;d0- next X
		sub.l		d2,d1				;d1- next Y
		cmp.l		d1,d6
		bgt.s		VBMEndVUX			;--> miny>Y (found slice)
		
		cmp.l		d5,d0
		bgt.s		VBMEndVUX			;--> X>maxx (found slice)				
VBMEndVUMid:		
		dbra		d7,VBMEndVUMidLoop0		;--> do next x
		
		move.l		(LAST,sp),d2
		subq.l		#$01,d0				;d0- next X (a bit redundant, but may
								;    be needed later if I want more info)
		sub.l		d2,d1				;d1- next Y
VBMEndVUX:
		subq.l		#$01,d0				;d0- last X 
		addq.l		#$01,d1				;d1- last Y (of this slice)
		move.l		d6,d4
		sub.l		d1,d4				;d4- miny-Y
		blt.s		VBMEndX				;--> Y>miny, so length already accurate
		
		sub.l		d4,d2				;d2- new slice length
		move.l		d6,d1				;d1- last Y (=miny)



	;	
	;common exit for end clip. re-defines the line.
	;(d0- final X, d1- final Y, d2- final SLICE length, d7- SLICES)
	; ^^           ^^  - not used currently
	;d7=SLICES means the first slice was clipped
	;d7=-1 means the last slice was clipped
	;other values indicate the clipped slice number (in some confusing roundabout sort of way)
	;
		
VBMEndX:		
		cmp.l		(SLICES,SP),d7
		bne.s		VBMEndXs0			;--> not the first slice
		
		clr.l		(SLICES,sp)			;no SLICES
		clr.l		(LAST,sp)			;no LAST
		move.l		d2,(FIRST,sp)			;new FIRST		
		bra.s		VBMRender			;--> out
VBMEndXs0:
		tst.l		d7
		bmi.s		VBMEndXs1			;--> twas the last slice
		
		move.l		(SLICES,sp),d4
		addq.l		#$01,d7
		sub.l		d7,d4	
		move.l		d4,(SLICES,sp)			;new SLICES (maybe)	
VBMEndXs1:		
		move.l		d2,(LAST,sp)			;new LAST
		




	;		
	;render the line... finally?
	;
		
VBMRender:	
		move.l		(SPACE+32,sp),a0		;a0- *bitmap
		moveq		#$00,d3
		move.l		(STARTY,sp),d2
		move.w		(bm_BytesPerRow,a0),d3		;d3- row mod
		muls.w		d3,d2				;d2- first row offset
		btst		#VBM_YDIRECTION,(FLAG,sp)
		beq.s		VBMRends0			;--> +ve Y
		
		neg.l		d3				;-ve Y
VBMRends0:
		move.l		(SPACE+16,sp),d5		;d5- pen1|pen0:mask|flags
		move.w		(SPACE+20,sp),d0		;d0- ****:pttrn
		swap		d0
		move.w		(SPACE+20,sp),d0		;d0- pttrn
		btst		#FB_INVERSVID,d5
		beq.s		VBMRends1			;--> no inverse video
		
		not.l		d0
VBMRends1:

	;
	;sort out the pattern, this lot should probably be combined, but my brains not up to it just now...
	;
	
		btst		#VBM_REVERSE,(FLAG,sp)
		bne.s		VBMRends2			;--> reverse
		
		moveq		#$0f,d4				;d4- shift
		sub.w		(SPACE+22,sp),d4		;patcnt shift
		add.l		(INITCLIP,sp),d4
		and.l		#$0f,d4
		rol.l		d4,d0
		bra.s		VBMRends3			;--> continue
VBMRends2:		
		moveq		#$0f,d4
		sub.w		(SPACE+22,sp),d4
		and.l		#$0f,d4
		rol.l		d4,d0				;patcnt shifted pattern		
		jsr		(_LVOReverseLong,a6)		;reverse (we goin backwad)
		move.l		#$10,d4
		sub.l		(TOTALPIX,sp),d4		;start at end
		add.l		(INITCLIP,sp),d4
		and.l		#$0f,d4
		rol.l		d4,d0
VBMRends3:
		move.l		d0,d1				;d1- pattern
				
		move.l		(RUN,sp),d7			;d7- run slice
		swap		d7				;d7- slice:0000
		
		move.l		(SLICES,sp),d0
		swap		d0
		move.w		(STARTX+2,sp),d0
		
		move.w		(LAST+2,sp),d4			
		swap		d4
		move.w		(FIRST+2,sp),d4
		move.l		d4,a3
		
		move.l		(FRACTION,sp),a5
		
		moveq		#$00,d6
		move.b		(bm_Depth,a0),d6		;d6- #planes		
		subq.l		#$01,d6
		bmi		VBMx				;--> no planes

		clr.w		d7
		btst		#FB_COMPLEMENT,d5
		beq.s		VBMjam1				;--> not complement

	;complement
	
		lsr.w		#$08,d5				;d5- mask
		move.l		sp,a2				;a2- saved sp
VBMcompl1:		
		btst		d6,d5
		beq.s		VBMcomps1			;--> plane masked
	
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
VBMcomps1:		
		dbra		d6,VBMcompl1
		
		tst.w		d7
		beq		VBMx				;--> all planes masked
		
		move.l		sp,a4				;a4- *planes
		move.l		(ERROR,a2),d4
		btst		#VBM_HORIZONTAL,(FLAG,a2)	;*** a2 = original sp!
		bne.s		VBMcomps2			;--> horizontal
		
		jsr		(_LVOCompVectorPlanesVert,a6)
		move.l		a2,sp				;restore stack
		bra		VBMx
VBMcomps2:
		jsr		(_LVOCompVectorPlanesHoriz,a6)
		move.l		a2,sp
		bra		VBMx		
	
	;jam1
	
VBMjam1:
		btst		#FB_JAM2,d5
		bne.s		VBMjam2				;--> jam2		
		
		;for pen1=1, set pttrn 1s in planes
VBMjam1s0:
		move.l		d5,d4
		lsr.w		#$08,d5				;d5- mask
		move.l		d6,a1				;a1- #planes-1
		swap		d4				;d4- pen1
		move.l		sp,a2				;a2- stack
VBMjam1l1:
		btst		d6,d5
		beq.s		VBMjam1s1			;--> masked
		
		btst		d6,d4
		beq.s		VBMjam1s1			;--> clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
		bclr		d6,d5				;don't look at this one again
VBMjam1s1:
		dbra		d6,VBMjam1l1
		
		tst.w		d7
		beq.s		VBMjam1s2			;--> no planes to fill
		
		move.l		sp,a4
		move.l		(ERROR,a2),d4
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam1s1a			;--> horizontal
		
		jsr		(_LVOFillVectorPlanesVert,a6)
		move.l		a2,sp
		bra.s		VBMjam1s2
VBMjam1s1a:
		jsr		(_LVOFillVectorPlanesHoriz,a6)
		move.l		a2,sp		
			
		;for pen1=0, clear pttrn 1s in planes
		
VBMjam1s2:
		move.l		a1,d6				;d6- #planes-1
		clr.b		d7
		move.l		sp,a2
VBMjam1l2:
		btst		d6,d5
		beq.s		VBMjam1s3			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
VBMjam1s3:
		dbra		d6,VBMjam1l2
		
		tst.w		d7
		beq		VBMx				;--> all done
		
		move.l		sp,a4
		move.l		(ERROR,a2),d4
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam1s3a			;--> horizontal
		
		jsr		(_LVOClearVectorPlanesVert,a6)
		move.l		a2,sp
		bra		VBMx				;--> all done
VBMjam1s3a:
		jsr		(_LVOClearVectorPlanesHoriz,a6)
		move.l		a2,sp
		bra		VBMx		
		
	;jam2		
		
VBMjam2:		
		not.l		d1
		bne.s		VBMjam2s0			;--> pattern !=%1111...
		
		moveq		#-1,d1
		bra		VBMjam1s0			;--> do as JAM1
VBMjam2s0:
		not.l		d1		
		bne.s		VBMjam2s00			;--> pattern !=%0000...
		
		swap		d5
		moveq		#-1,d1
		lsr.w		#$08,d5
		swap		d5
		bra		VBMjam1s0			;--> do as jam1 (with pens reversed)

		;clear vector where pen0=0 and pen1=0 (pttrn set to 1s)
		
VBMjam2s00:		
		move.l		d5,d4
		lsr.l		#$08,d5				;d5- 00|pen0:pen1|mask
		swap		d4				;d4- pen0|pen1
		move.l		d6,a1				;a1- #planes-1
		move.l		d4,(TEMP,sp)			;save pen0|pen1
		swap		d5				;d5- pen1|mask:00|pen0
		or.b		d5,d4
		swap		d5
		move.l		sp,a2
VBMjam2l1:
		btst		d6,d5
		beq.s		VBMjam2s1			;--> masked
		
		btst		d6,d4
		bne.s		VBMjam2s1			;--> don't clear this plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
		bclr		d6,d5				;mask this plane
VBMjam2s1:
		dbra		d6,VBMjam2l1
		
		tst.w		d7
		beq.s		VBMjam2s2			;--> no planes to clear
		
		move.l		sp,a4	
		move.l		d1,d6				;d6 - pattern
		moveq		#-1,d1
		move.l		(ERROR,a2),d4		
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam2s1a
		
		jsr		(_LVOClearVectorPlanesVert,a6)		
		move.l		d6,d1
		bra.s		VBMjam2s2
VBMjam2s1a:
		jsr		(_LVOClearVectorPlanesHoriz,a6)		
		move.l		d6,d1
		
		;fill vector for pen0=1 and pen1=1 (set pttrn to 1s)
		
VBMjam2s2:
		move.l		(TEMP,a2),d4				;d4- pen0|pen1
		swap		d5
		and.b		d5,d4
		move.l		a1,d6				;d6- #planes-1
		swap		d5
		clr.w		d7
		move.l		a2,sp
VBMjam2l2:
		btst		d6,d5
		beq.s		VBMjam2s3			;--> masked
		
		btst		d6,d4
		beq.s		VBMjam2s3			;--> don't fill plane
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
		bclr		d6,d5				;mask plane
VBMjam2s3:
		dbra		d6,VBMjam2l2
		
		tst.w		d7
		beq.s		VBMjam2s4			;--> no planes to fill

		move.l		sp,a4
		move.l		d1,d6
		move.l		(ERROR,a2),d4
		moveq		#-1,d1
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam2s3a
		
		jsr		(_LVOFillVectorPlanesVert,a6)
		move.l		d6,d1
		bra.s		VBMjam2s4
VBMjam2s3a:
		jsr		(_LVOFillVectorPlanesHoriz,a6)		
		move.l		d6,d1
		
		;copy pttrn for pen0=0 and pen1=1
		
VBMjam2s4:
		move.l		(TEMP,a2),d4				;d4- pen0|pen1
		move.l		a1,d6				;d6- #planes
		clr.w		d7
		move.l		a2,sp
VBMjam2l3:
		btst		d6,d5
		beq.s		VBMjam2s5			;--> masked
		
		btst		d6,d4
		beq.s		VBMjam2s5			;--> pen0=1, pen1=0, do later
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
		bclr		d6,d5				;mask plane
VBMjam2s5:
		dbra		d6,VBMjam2l3
		
		tst.w		d7
		beq.s		VBMjam2s6			;--> no planes to fill
		
		move.l		sp,a4
		move.l		(ERROR,a2),d4
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam2s5a
		
		jsr		(_LVOCopyVectorPlanesVert,a6)
		bra.s		VBMjam2s6
VBMjam2s5a:
		jsr		(_LVOCopyVectorPlanesHoriz,a6)		
		
		;copy ~pttrn for pen0=1 and pen1=0
		
VBMjam2s6:
		move.l		a1,d6
		clr.w		d7
		move.l		a2,sp
VBMjam2l4:
		btst		d6,d5
		beq.s		VBMjam2s7			;--> masked
		
		move.l		(bm_Planes,a0,d6.l*4),-(sp)
		addq.l		#$01,d7
VBMjam2s7:		
		dbra		d6,VBMjam2l4				
	
		tst.w		d7
		beq.s		VBMx
		
		move.l		sp,a4
		move.l		(ERROR,a2),d4
		not.l		d1
		btst		#VBM_HORIZONTAL,(FLAG,a2)
		bne.s		VBMjam2s7a
		
		jsr		(_LVOCopyVectorPlanesVert,a6)
		move.l		a2,sp
		bra.s		VBMx			
VBMjam2s7a:
		jsr		(_LVOCopyVectorPlanesHoriz,a6)
		move.l		a2,sp		
		
	;common exit...
			
VBMx:
		add.l		#SPACE,sp
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		
		
		
		
	