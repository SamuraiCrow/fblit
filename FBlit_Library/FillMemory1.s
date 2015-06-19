

*-----------------------------------------------------------------------------
*
*	FillMemory.s V1.0 10.02.2002
*
*	© Stephen Brookes 2002
*
*	This is basically BltClear(), and is a pretty straight copy of the
*	business part of FBltClear. The FBltClear patch itself is still part of
*	the FBlit exe (it just calls this function).
*
*-----------------------------------------------------------------------------
*
* Input:		d0=ByteCnt.l	(see BltClear()...)
*			d1=Flags.l
*			a1=*MemBlock
*
* Output:		-
*
* Trashed:		- nothing (seems to be the way this lib goes..)
*
*-----------------------------------------------------------------------------


FillMemory:
		movem.l		d2-d6/a1,-(sp)
		jsr		(_LVOGetBlitter,a6)		;lock blitter

	;round #bytes down to nearest word
	
		moveq		#-2,d2
		and.l		d0,d2				;d2- #bytes rounded to nearest word

	;figure out real #bytes
	
		btst		#$01,d1 			;flag bit 1
		beq.s		FMs0				;--> d2- #bytes

		move.w		d2,d3				;d3- rows:bytes
		swap		d2				;d2- bytes:rows
		mulu.w		d3,d2				;d2- #bytes

	;set up the fill

FMs0:
		moveq		#0,d3
		btst		#$02,d1 			;flag bit 2
		beq.s		FMs1				;--> clear mode

		move.l		d1,d3				;d3- fill:xxxx
		swap		d1				;d1- flag:fill
		move.w		d1,d3				;d3- fill:fill
		swap		d1				;d1- fill:flag

	;round dest addx down to nearest word

FMs1:	
		move.l		a1,d4				;d4- dest
		bclr		#$00,d4 			;round to word
		move.l		d4,a1

	;lw align dest
			
		btst		#$01,d4 			;odd word?
		beq.s		FMs2				;--> already aligned

		subq.l		#$02,d2 			;-1 word
		bcs.s		FMX				;--> nothing to do!
		
		move.w		d3,(a1)+			;fill 1 word
		
	;do the fill
	;Note: there may be no bytes to fill, but it's not likely enough to be worth checking.
FMs2:
		move.l		d3,d4				;d4- fill.l
		move.l		d3,d5				;d5- fill.l
		move.l		d3,d6				;d6- fill.l

		lsr.l		#$02,d2 			;#bytes to #longs
		lea		(a1,d2.l*4),a1			;a1- last lw
		bcc.s		FMs3				;--> no word overhang
		
		move.w		d3,(a1)

	;any longs?

FMs3:
		lsr.l		#$01,d2
		bcc.s		FMs4				;--> no longs

		move.l		d3,-(a1)

	;any quads?

FMs4:
		lsr.l		#$01,d2
		bcc.s		FMs5				;--> no quads

		movem.l 	d3-d4,-(a1)

	;any octets?

FMs5:		lsr.l		#$01,d2
		bcc.s		FMs6				;--> no octets

		movem.l 	d3-d6,-(a1)

	;finish sixteens

		subq.l		#$01,d2
		bmi.s		FMX				;--> all done
FMl0:
		movem.l 	d3-d6,-(a1)
		movem.l 	d3-d6,-(a1)
FMs6:		
	        subq.l		#$01,d2
	        bpl.s		FMl0				;--> do some more

	;exit
	
FMX:
		movem.l		(sp)+,d2-d6/a1
		jmp		(_LVOFreeBlitter,a6)		;--> exit/release lock

