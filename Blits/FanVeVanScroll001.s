

*-----------------------------------------------------------------------------
*
*	FanVeVanScroll.s V0.1 12.12.98
*
*	© Stephen Brookes 1997-98
*
*	Fancy Vertical Vanilla Scroll
*
*-----------------------------------------------------------------------------
*
* Input:		-
*
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


FanVeVanScroll:
		lea		(_Planes,a6,d1.w*8),a0
		movem.l		(a0),a0/a1			;a0/a1- *planes
		add.l		(l_SrcXFLW,a6),a1
		add.l		(l_DstXFLW,a6),a0
		
FVVHead:
		move.l		(l_BTH,a6),d1
		tst.b		d1
		beq.s		FVVBody				;--> no head bits
		
		lea		(4,a0),a2			;a2- next dst lw
		lea		(4,a1),a3
		move.l		(l_DstStart,a6),d2
		bsr.s		FVVHT
		move.l		a2,a0
		move.l		a3,a1
		
FVVBody:
		swap		d1
		tst.w		d1
		beq.s		FVVTail				;--> no body
		
		lea		(a0,d1.w*4),a2			;a2- next lw
		lea		(a1,d1.w*4),a3
		subq.w		#$01,d1
		bsr.s		FVVB
		move.l		a2,a0
		move.l		a3,a1
		
FVVTail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FVVEndLoop			;--> no tail
		
		moveq		#$00,d2
		bsr.s		FVVHT
		
FVVEndLoop:
		move.w		(w_DynNP,a6),d1
		subq.w		#$01,d1
		move.w		d1,(w_DynNP,a6)
		bpl		FanVeVanScroll
		bra		DisBlitX
					
					
	;fancy scroll head/tail loop
	;d1=mask size
	;d2=src/dst start
	;a0=dst addr
	;a1=src addr
	;a5=src/dst delta

FVVHT:
		move.w		(w_Rows,a6),d7			;d7- ????:Rows
		moveq		#0,d3				;d3- $0
		bfset		d3{d2:d1}			;d3- mask
		move.l		d3,d4
		not.l		d4				;d4- !mask
		move.l		(a0),d0				;precharge buffer
		and.l		d3,d0

FVVHTl0:
		move.l		(a1),d6				;d6- src
		and.l		d3,d6				;    &mask
		cmp.l		d6,d0
		beq.s		FVVHTl0s0			;--> src=dst
		
		move.l		(a0),d0				;d0- dst
		and.l		d4,d0				;    &!mask		
		or.l		d6,d0				;d0- (src&mask)|(dst&!mask)
		move.l		d0,(a0)
		move.l		d6,d0				;load buffer
		
FVVHTl0s0:
		add.l		a5,a0				;next row
		add.l		a5,a1
		dbra		d7,FVVHTl0
		moveq		#0,d0
		rts



	;fancy scroll body loop
	;d1=lw count
	;a0=dst
	;a1=src
	;a5=src/dst delta

FVVB:
		move.w		(w_Rows,a6),d7			;d7- ????:Rows
FVVBl0:	
		moveq		#$00,d2
		move.w		d7,d4				;d4- ****:Rows
		move.w		d1,d2
		lsl.l		#$02,d2
		move.l		(d2.l,a0),d0			;precharge buffer		
FVVBl1:		
		move.l		(d2.l,a1),d6			;d3- src
		cmp.l		d6,d0
		beq.s		FVVBl1s0			;--> dst=src
		
		move.l		d6,(d2.l,a0)
		move.l		d6,d0
FVVBl1s0:
		add.l		a5,d2
		dbra		d4,FVVBl1			;--> do all rows		
		
		dbra		d1,FVVBl0
		rts

			
					
												