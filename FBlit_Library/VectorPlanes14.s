



	;
	;FillVectorPlanesVert/Horiz	(set pattern 1's in all planes)
	;<d0- rows.w:destx.w (#rows/columns.w(-2):destx.w(1st pixel))
	; d1- pattern.l (MSB=1st rendered)
	; d2- offset.l (offset to 1st row)
	; d3- destmod.l (row modulos (and direction ie. signed))
	; d4- error.l (initial error, 30bit signed fraction)
	; d5- 
	; d6- 
	; d7- slice.w:#planes.w (slice = minumum slice length)
	;
	; a3- endlength.w:startlength.w
	; a4- *planes (pointer to array of *planes)
	; a5- advance.l (error/slice, 30bit signed fraction)
	; 
	;>
	;all reg's preserved
	;


FillVectorPlanesVert:

		movem.l		d0-d7/a0-a6,-(sp)
	
		subq.w		#$01,d7				;d7- slice.w:#planes.w-1
		sub.l		#$10000,d7
		move.l		d1,a2				;a2- pattern init
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset
		
		cmp.l		#-1,d1
		beq.s		FVPVNonPatterned		;--> no pattern (ie. pattern all ones)		

FVPVPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		a2,d6				;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w-1:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		FVPVStartSkip1			;--> to end of loop
FVPVStartLoop:
		rol.l		#$01,d6
		bcc.s		FVPVStartSkip0			;--> pattern bit = 0
		
		bfset		(a0){d1:1}
FVPVStartSkip0:
		add.l		d3,a0				;a0- next y
FVPVStartSkip1:		
		dbra		d4,FVPVStartLoop		;--> do next y
		
		addq.l		#$01,d1				;d1- next x
		
		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w(columns in fact)
		swap		d0	
		bra.s		FVPVMidSkip1			;--> to end of loop
FVPVMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		FVPVMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
FVPVMidLoop1:
		rol.l		#$01,d6
		bcc.s		FVPVMidSkip0			;--> pattern bit = 0
		
		bfset		(a0){d1:1}
FVPVMidSkip0:
		add.l		d3,a0				;a0- next y	
		dbra		d2,FVPVMidLoop1			;--> do next y
		
		addq.l		#$01,d1				;d1- next x
FVPVMidSkip1:
		dbra		d4,FVPVMidLoop0			;--> do next x
						
						
		swap		d4				;d4- endlength.w
		bra.s		FVPVEndSkip1			;--> to end of loop
FVPVEndLoop:
		rol.l		#$01,d6
		bcc.s		FVPVEndSkip0			;--> pattern bit = 0
		
		bfset		(a0){d1:1}
FVPVEndSkip0:
		add.l		d3,a0				;a0- next y
FVPVEndSkip1:		
		dbra		d4,FVPVEndLoop			;--> do next y
		
		swap		d7				;d7- slice.w:#planes.w-1
		dbra		d7,FVPVPlaneLoop		;--> next plane
	
		bra.s		FVPVx				;--> exit
		
	;	
	;non-patterned fill vertical		
	;
		
FVPVNonPatterned:
		move.l		#$80000000,d6			;d6- mask (or whatever)
		moveq		#$1f,d1
		and.w		d0,d1				;destx & #$1f
		lsr.l		d1,d6				;d6- initial mask
		sub.w		d1,d0	
		lsr.w		#$03,d0				;d0- initial destx (bytes (lw!))
		add.w		d0,a6				;a6- initial plane offset (bytes (lw))
		move.l		d6,a2				;a2- initial mask
				
FVPVNPPlaneLoop:		
		move.l		(a4,d7.w*4),a0			;a0- this plane
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first lw
		move.l		a2,d1				;d1- init mask
		swap		d7				;d7- #planes.w-1:slice.w
		sub.l		d3,a0				;precharge
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		subq.w		#$01,d4				;note it is *impossible* for startlength
								;to be zero initially!
		move.w		d4,d2
		move.w		(sp),d4
		bra.s		FVPVNPMidLoop1
FVPVNPMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		FVPVNPMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
FVPVNPMidLoop1:
		addq.w		#$01,d2
FVPVNPMidLoop2:
		subq.w		#$01,d2
		bmi.s		FVPVNPMidSkip2
				
		add.l		d3,a0
		move.l		(a0),d6
		move.l		d1,d0
		or.l		d6,d0
		cmp.l		d6,d0
		beq.s		FVPVNPMidLoop2
		
		move.l		d0,(a0)
		bra.s		FVPVNPMidLoop2
FVPVNPMidSkip2:		
		ror.l		#$01,d1				;d1- next x
		bcc.s		FVPVNPMidSkip3			;--> no overflow
		
		addq.l		#$04,a0				;next x lw
FVPVNPMidSkip3:
		dbra		d4,FVPVNPMidLoop0		;--> do next x
						
		swap		d4				;d4- endlength.w
		subq.w		#$01,d4
		bmi.s		FVPVNPPlanex			;--> all done (next plane)
		
		move.w		d4,d2
		clr.w		d4
		bra.s		FVPVNPMidLoop1			;--> to end slice	
FVPVNPPlanex:
		swap		d7
		dbra		d7,FVPVNPPlaneLoop		;--> next plane
FVPVx:		
		movem.l		(sp)+,d0-d7/a0-a6
		rts




		
FillVectorPlanesHoriz:

		movem.l		d0-d7/a0-a6,-(sp)

		subq.w		#$01,d7		
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
FVPHPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		(4,sp),d6			;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		FVPHStartSkip0			;--> enter loop		
FVPHStartLoop:
		bfextu		(a0){d1:32},d2
		or.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d4
FVPHStartSkip0:
		cmp.w		#$21,d4
		bcc.s		FVPHStartLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		FVPHStartExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		or.l		d6,d2
		bfins		d2,(a0){d1:d4}
		add.w		d4,d1				;d1- next x
FVPHStartExit:
		add.l		d3,a0				;a0- next y		
	

		
FVPHMid:		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w
		swap		d0	
		move.l		d0,a2				;save d0
		bra.s		FVPHMidSkip2			;--> to end of loop
FVPHMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		FVPHMidSkip0			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
		bra.s		FVPHMidSkip0			;--> enter loop
FVPHMidLoop1:
		bfextu		(a0){d1:32},d0
		or.l		d6,d0
		bfins		d0,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d2
FVPHMidSkip0:
		cmp.w		#$21,d2
		bcc.s		FVPHMidLoop1			;--> >32pixels
		
		tst.w		d2
		beq.s		FVPHMidSkip1			;--> all done
		
		bfextu		(a0){d1:d2},d0
		rol.l		d2,d6
		or.l		d6,d0
		bfins		d0,(a0){d1:d2}
		add.w		d2,d1				;next x
FVPHMidSkip1:	
		add.l		d3,a0				;next y
FVPHMidSkip2:		
		dbra		d4,FVPHMidLoop0			;--> do next y
		
		move.l		a2,d0				;recover d0

		
		swap		d4
		bra.s		FVPHEndSkip0			;--> enter loop
FVPHEndLoop:		
		bfextu		(a0){d1:32},d2
		or.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d0- next x
		sub.w		#$20,d4
FVPHEndSkip0:
		cmp.w		#$21,d4
		bcc.s		FVPHEndLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		FVPHEndExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		or.l		d6,d2
		bfins		d2,(a0){d1:d4}
FVPHEndExit:

		
		swap		d7				;d7- slice.w:#planes.w
		dbra		d7,FVPHPlaneLoop		;--> next plane
		
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		
		
	
	
	;
	;same stuff, for clear
	;		
		
		
ClearVectorPlanesVert:
		movem.l		d0-d7/a0-a6,-(sp)
	
		subq.w		#$01,d7				;d7- slice.w:#planes.w-1
		sub.l		#$10000,d7
		move.l		d1,a2				;a2- pattern init
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
		
		cmp.l		#-1,d1
		beq.s		CVPVNonPatterned		;--> no pattern

CVPVPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		a2,d6				;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w-1:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		CVPVStartSkip1			;--> to end of loop
CVPVStartLoop:
		rol.l		#$01,d6
		bcc.s		CVPVStartSkip0			;--> pattern bit = 0
		
		bfclr		(a0){d1:1}
CVPVStartSkip0:
		add.l		d3,a0				;a0- next y
CVPVStartSkip1:		
		dbra		d4,CVPVStartLoop		;--> do next y
		
		addq.l		#$01,d1				;d1- next x
		
		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w(columns in fact)
		swap		d0	
		bra.s		CVPVMidSkip1			;--> to end of loop
CVPVMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		CVPVMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
CVPVMidLoop1:
		rol.l		#$01,d6
		bcc.s		CVPVMidSkip0			;--> pattern bit = 0
		
		bfclr		(a0){d1:1}
CVPVMidSkip0:
		add.l		d3,a0				;a0- next y	
		dbra		d2,CVPVMidLoop1			;--> do next y
		
		addq.l		#$01,d1				;d1- next x
CVPVMidSkip1:
		dbra		d4,CVPVMidLoop0			;--> do next x
						
						
		swap		d4				;d4- endlength.w
		bra.s		CVPVEndSkip1			;--> to end of loop
CVPVEndLoop:
		rol.l		#$01,d6
		bcc.s		CVPVEndSkip0			;--> pattern bit = 0
		
		bfclr		(a0){d1:1}
CVPVEndSkip0:
		add.l		d3,a0				;a0- next y
CVPVEndSkip1:		
		dbra		d4,CVPVEndLoop			;--> do next y
		
		swap		d7				;d7- slice.w:#planes.w-1
		dbra		d7,CVPVPlaneLoop		;--> next plane
		
		bra.s		CVPVx

	;
	;non-patterned
	;
		
CVPVNonPatterned:
		move.l		#$7fffffff,d6			;d6- mask (or whatever)
		moveq		#$1f,d1
		and.w		d0,d1				;destx & #$1f
		ror.l		d1,d6				;d6- initial mask
		sub.w		d1,d0	
		lsr.w		#$03,d0				;d0- initial destx (bytes (lw!))
		add.w		d0,a6				;a0- initial plane offset (bytes (lw))
		move.l		d6,a2				;a2- initial mask
		
CVPVNPPlaneLoop:		
		move.l		(a4,d7.w*4),a0			;a0- this plane
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first lw
		move.l		a2,d1				;d1- init mask
		swap		d7				;d7- #planes.w-1:slice.w		
		sub.l		d3,a0				;precharge
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		subq.w		#$01,d4				;note it is *impossible* for startlength
								;to be zero initially!
		move.w		d4,d2
		move.w		(sp),d4
		bra.s		CVPVNPMidLoop1
CVPVNPMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		CVPVNPMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
CVPVNPMidLoop1:
		addq.w		#$01,d2
CVPVNPMidLoop2:
		subq.w		#$01,d2
		bmi.s		CVPVNPMidSkip2
				
		add.l		d3,a0
		move.l		(a0),d6
		move.l		d1,d0
		and.l		d6,d0
		cmp.l		d0,d6
		beq.s		CVPVNPMidLoop2
		
		move.l		d0,(a0)	
		bra.s		CVPVNPMidLoop2
CVPVNPMidSkip2:		
		ror.l		#$01,d1				;d1- next x
		bcs.s		CVPVNPMidSkip3			;--> no overflow
		
		addq.l		#$04,a0				;next x lw
CVPVNPMidSkip3:
		dbra		d4,CVPVNPMidLoop0		;--> do next x
						
		swap		d4				;d4- endlength.w
		subq.w		#$01,d4
		bmi.s		CVPVNPPlanex			;--> all done
		
		move.w		d4,d2
		clr.w		d4
		bra.s		CVPVNPMidLoop1			;--> to end slice
CVPVNPPlanex:		
		swap		d7
		dbra		d7,CVPVNPPlaneLoop		;--> next plane	
CVPVx:	
		movem.l		(sp)+,d0-d7/a0-a6
		rts





	
		
		
ClearVectorPlanesHoriz:
		movem.l		d0-d7/a0-a6,-(sp)

		subq.w		#$01,d7		
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
CVPHPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		(4,sp),d6			;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w:slice.w
		not.l		d6				;invert pttrn
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		CVPHStartSkip0			;--> enter loop		
CVPHStartLoop:
		bfextu		(a0){d1:32},d2
		and.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d4
CVPHStartSkip0:
		cmp.w		#$21,d4
		bcc.s		CVPHStartLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		CVPHStartExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		and.l		d6,d2
		bfins		d2,(a0){d1:d4}
		add.w		d4,d1				;d1- next x
CVPHStartExit:
		add.l		d3,a0				;a0- next y		
	

		
CVPHMid:		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w
		swap		d0	
		move.l		d0,a2				;save d0
		bra.s		CVPHMidSkip2			;--> to end of loop
CVPHMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		CVPHMidSkip0			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
		bra.s		CVPHMidSkip0			;--> enter loop
CVPHMidLoop1:
		bfextu		(a0){d1:32},d0
		and.l		d6,d0
		bfins		d0,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d2
CVPHMidSkip0:
		cmp.w		#$21,d2
		bcc.s		CVPHMidLoop1			;--> >32pixels
		
		tst.w		d2
		beq.s		CVPHMidSkip1			;--> all done
		
		bfextu		(a0){d1:d2},d0
		rol.l		d2,d6
		and.l		d6,d0
		bfins		d0,(a0){d1:d2}
		add.w		d2,d1				;next x
CVPHMidSkip1:	
		add.l		d3,a0				;next y
CVPHMidSkip2:		
		dbra		d4,CVPHMidLoop0			;--> do next y
		
		move.l		a2,d0				;recover d0

		
		swap		d4
		bra.s		CVPHEndSkip0			;--> enter loop
CVPHEndLoop:		
		bfextu		(a0){d1:32},d2
		and.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d0- next x
		sub.w		#$20,d4
CVPHEndSkip0:
		cmp.w		#$21,d4
		bcc.s		CVPHEndLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		CVPHEndExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		and.l		d6,d2
		bfins		d2,(a0){d1:d4}
CVPHEndExit:

		
		swap		d7				;d7- slice.w:#planes.w
		dbra		d7,CVPHPlaneLoop		;--> next plane
		
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		

	;
	;note that there is no special non-patterned routine for 'copy' mode
	;such operations should be directed to 'fill' or 'clear' instead
	;
		
		
CopyVectorPlanesVert:
		movem.l		d0-d7/a0-a6,-(sp)
	
		subq.w		#$01,d7				;d7- slice.w:#planes.w-1
		sub.l		#$10000,d7
		move.l		d1,a2				;a2- pattern init
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
COPVPVPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		a2,d6				;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w-1:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		COPVPVStartSkip1		;--> to end of loop
COPVPVStartLoop:
		rol.l		#$01,d6
		bfins		d6,(a0){d1:1}
COPVPVStartSkip0:
		add.l		d3,a0				;a0- next y
COPVPVStartSkip1:		
		dbra		d4,COPVPVStartLoop		;--> do next y
		
		addq.l		#$01,d1				;d1- next x
		
		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w(columns in fact)
		swap		d0	
		bra.s		COPVPVMidSkip1			;--> to end of loop
COPVPVMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		COPVPVMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
COPVPVMidLoop1:
		rol.l		#$01,d6
		bfins		d6,(a0){d1:1}
COPVPVMidSkip0:
		add.l		d3,a0				;a0- next y	
		dbra		d2,COPVPVMidLoop1			;--> do next y
		
		addq.l		#$01,d1				;d1- next x
COPVPVMidSkip1:
		dbra		d4,COPVPVMidLoop0			;--> do next x
						
						
		swap		d4				;d4- endlength.w
		bra.s		COPVPVEndSkip1			;--> to end of loop
COPVPVEndLoop:
		rol.l		#$01,d6
		bfins		d6,(a0){d1:1}
COPVPVEndSkip0:
		add.l		d3,a0				;a0- next y
COPVPVEndSkip1:		
		dbra		d4,COPVPVEndLoop			;--> do next y
		
		swap		d7				;d7- slice.w:#planes.w-1
		dbra		d7,COPVPVPlaneLoop		;--> next plane
COPVPVx:	
		movem.l		(sp)+,d0-d7/a0-a6
		rts



		
CopyVectorPlanesHoriz:

		movem.l		d0-d7/a0-a6,-(sp)

		subq.w		#$01,d7		
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
COPVPHPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		(4,sp),d6			;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		COPVPHStartSkip0			;--> enter loop		
COPVPHStartLoop:
		bfins		d6,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d4
COPVPHStartSkip0:
		cmp.w		#$21,d4
		bcc.s		COPVPHStartLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		COPVPHStartExit			;--> all done
		
		rol.l		d4,d6
		bfins		d6,(a0){d1:d4}
		add.w		d4,d1				;d1- next x
COPVPHStartExit:
		add.l		d3,a0				;a0- next y		
	

		
COPVPHMid:		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w
		swap		d0	
		move.l		d0,a2				;save d0
		bra.s		COPVPHMidSkip2			;--> to end of loop
COPVPHMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		COPVPHMidSkip0			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
		bra.s		COPVPHMidSkip0			;--> enter loop
COPVPHMidLoop1:
		bfins		d6,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d2
COPVPHMidSkip0:
		cmp.w		#$21,d2
		bcc.s		COPVPHMidLoop1			;--> >32pixels
		
		tst.w		d2
		beq.s		COPVPHMidSkip1			;--> all done
		
		rol.l		d2,d6
		bfins		d6,(a0){d1:d2}
		add.w		d2,d1				;next x
COPVPHMidSkip1:	
		add.l		d3,a0				;next y
COPVPHMidSkip2:		
		dbra		d4,COPVPHMidLoop0			;--> do next y
		
		move.l		a2,d0				;recover d0

		
		swap		d4
		bra.s		COPVPHEndSkip0			;--> enter loop
COPVPHEndLoop:		
		bfins		d6,(a0){d1:32}
		
		add.l		#$20,d1				;d0- next x
		sub.w		#$20,d4
COPVPHEndSkip0:
		cmp.w		#$21,d4
		bcc.s		COPVPHEndLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		COPVPHEndExit			;--> all done
		
		rol.l		d4,d6
		bfins		d6,(a0){d1:d4}
COPVPHEndExit:

		
		swap		d7				;d7- slice.w:#planes.w
		dbra		d7,COPVPHPlaneLoop		;--> next plane
		
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		
	
	;
	;'complement' mode
	;	

		
CompVectorPlanesVert:
		movem.l		d0-d7/a0-a6,-(sp)
	
		subq.w		#$01,d7				;d7- slice.w:#planes.w-1
		sub.l		#$10000,d7
		move.l		d1,a2				;a2- pattern init
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset	
		
		cmp.l		#-1,d1
		beq.s		COMVPVNonPatterned		;--> no pattern
			
COMVPVPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		a2,d6				;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w-1:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		COMVPVStartSkip1		;--> to end of loop
COMVPVStartLoop:
		rol.l		#$01,d6
		bcc.s		COMVPVStartSkip0		;--> pattern bit = 0
		
		bfchg		(a0){d1:1}
COMVPVStartSkip0:
		add.l		d3,a0				;a0- next y
COMVPVStartSkip1:		
		dbra		d4,COMVPVStartLoop		;--> do next y
		
		addq.l		#$01,d1				;d1- next x
		
		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w(columns in fact)
		swap		d0	
		bra.s		COMVPVMidSkip1			;--> to end of loop
COMVPVMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		COMVPVMidLoop1			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
COMVPVMidLoop1:
		rol.l		#$01,d6
		bcc.s		COMVPVMidSkip0			;--> pattern bit = 0
		
		bfchg		(a0){d1:1}
COMVPVMidSkip0:
		add.l		d3,a0				;a0- next y	
		dbra		d2,COMVPVMidLoop1		;--> do next y
		
		addq.l		#$01,d1				;d1- next x
COMVPVMidSkip1:
		dbra		d4,COMVPVMidLoop0		;--> do next x
						
						
		swap		d4				;d4- endlength.w
		bra.s		COMVPVEndSkip1			;--> to end of loop
COMVPVEndLoop:
		rol.l		#$01,d6
		bcc.s		COMVPVEndSkip0			;--> pattern bit = 0
		
		bfchg		(a0){d1:1}
COMVPVEndSkip0:
		add.l		d3,a0				;a0- next y
COMVPVEndSkip1:		
		dbra		d4,COMVPVEndLoop		;--> do next y
		
		swap		d7				;d7- slice.w:#planes.w-1
		dbra		d7,COMVPVPlaneLoop		;--> next plane

		bra.s		COMVPVx


	;	
	;non-patterned vertical	(note this one can't cheat since a pattern '1' will always change
	;the destination regardless of what that contains!)	
	;
		
COMVPVNonPatterned:
		move.l		#$80000000,d6			;d6- mask (or whatever)
		moveq		#$1f,d1
		and.w		d0,d1				;destx & #$1f
		lsr.l		d1,d6				;d6- initial mask
		sub.w		d1,d0	
		lsr.w		#$03,d0				;d0- initial destx (bytes (lw!))
		add.w		d0,a6				;a6- initial plane offset (bytes (lw))
		move.l		d6,a2				;a2- initial mask
				
COMVPVNPPlaneLoop:		
		move.l		(a4,d7.w*4),a0			;a0- this plane
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first lw
		move.l		a2,d1				;d1- init mask
		swap		d7				;d7- #planes.w-1:slice.w		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		subq.w		#$01,d4				;note it is *impossible* for startlength
								;to be zero initially!
		move.w		d4,d2
		move.w		(sp),d4
		bra.s		COMVPVNPMidLoop1
COMVPVNPMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		COMVPVNPMidLoop1		;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
COMVPVNPMidLoop1:
		move.l		(a0),d6				
		eor.l		d1,d6
		move.l		d6,(a0)
		add.l		d3,a0

		dbra		d2,COMVPVNPMidLoop1
COMVPVNPMidSkip2:		
		ror.l		#$01,d1				;d1- next x
		bcc.s		COMVPVNPMidSkip3		;--> no overflow
		
		addq.l		#$04,a0				;next x lw
COMVPVNPMidSkip3:
		dbra		d4,COMVPVNPMidLoop0		;--> do next x
						
		swap		d4				;d4- endlength.w
		subq.w		#$01,d4
		bmi.s		COMVPVNPPlanex			;--> all done (next plane)
		
		move.w		d4,d2
		clr.w		d4
		bra.s		COMVPVNPMidLoop1		;--> to end slice	
COMVPVNPPlanex:
		swap		d7
		dbra		d7,COMVPVNPPlaneLoop		;--> next plane
COMVPVx:		
		movem.l		(sp)+,d0-d7/a0-a6
		rts





		
CompVectorPlanesHoriz:
		movem.l		d0-d7/a0-a6,-(sp)

		subq.w		#$01,d7		
		move.l		d4,a1				;a1- error init
		move.l		d2,a6				;a6- row offset		
COMVPHPlaneLoop:		
		move.l		(a4,d7.w*4),a0
		moveq		#$00,d1
		move.l		(4,sp),d6			;d6- pattern
		move.l		a1,d5				;d5- initial error
		add.l		a6,a0				;a0- plane, first row
		move.w		d0,d1				;d1- destx.l
		swap		d7				;d7- #planes.w:slice.w
		
		
		move.l		a3,d4				;d4- endlength.w:startlength.w
		bra.s		COMVPHStartSkip0		;--> enter loop		
COMVPHStartLoop:
		bfextu		(a0){d1:32},d2
		eor.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d4
COMVPHStartSkip0:
		cmp.w		#$21,d4
		bcc.s		COMVPHStartLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		COMVPHStartExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		eor.l		d6,d2
		bfins		d2,(a0){d1:d4}
		add.w		d4,d1				;d1- next x
COMVPHStartExit:
		add.l		d3,a0				;a0- next y		
	

		
COMVPHMid:		
		swap		d0
		move.w		d0,d4				;d4- endlength.w:rows.w
		swap		d0	
		move.l		d0,a2				;save d0
		bra.s		COMVPHMidSkip2			;--> to end of loop
COMVPHMidLoop0:
		move.w		d7,d2				;d2- slice
		add.l		a5,d5				;next error
		bmi.s		COMVPHMidSkip0			;--> no overflow
		
		addq.w		#$01,d2				;d2- long slice
		sub.l		#$40000000,d5			;reset error		
		bra.s		COMVPHMidSkip0			;--> enter loop
COMVPHMidLoop1:
		bfextu		(a0){d1:32},d0
		eor.l		d6,d0
		bfins		d0,(a0){d1:32}
		
		add.l		#$20,d1				;d1- next x
		sub.w		#$20,d2
COMVPHMidSkip0:
		cmp.w		#$21,d2
		bcc.s		COMVPHMidLoop1			;--> >32pixels
		
		tst.w		d2
		beq.s		COMVPHMidSkip1			;--> all done
		
		bfextu		(a0){d1:d2},d0
		rol.l		d2,d6
		eor.l		d6,d0
		bfins		d0,(a0){d1:d2}
		add.w		d2,d1				;next x
COMVPHMidSkip1:	
		add.l		d3,a0				;next y
COMVPHMidSkip2:		
		dbra		d4,COMVPHMidLoop0			;--> do next y
		
		move.l		a2,d0				;recover d0

		
		swap		d4
		bra.s		COMVPHEndSkip0			;--> enter loop
COMVPHEndLoop:		
		bfextu		(a0){d1:32},d2
		eor.l		d6,d2
		bfins		d2,(a0){d1:32}
		
		add.l		#$20,d1				;d0- next x
		sub.w		#$20,d4
COMVPHEndSkip0:
		cmp.w		#$21,d4
		bcc.s		COMVPHEndLoop			;--> >32pixels
		
		tst.w		d4
		beq.s		COMVPHEndExit			;--> all done
		
		bfextu		(a0){d1:d4},d2
		rol.l		d4,d6
		eor.l		d6,d2
		bfins		d2,(a0){d1:d4}
COMVPHEndExit:

		
		swap		d7				;d7- slice.w:#planes.w
		dbra		d7,COMVPHPlaneLoop		;--> next plane
		
		movem.l		(sp)+,d0-d7/a0-a6
		rts
		

						
		
		
									
		
		
		