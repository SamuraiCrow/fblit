

*-----------------------------------------------------------------------------
*
*	BlitEm.s V0.044 15.12.98
*
*	© Stephen Brookes 1997-98
*
*	020+ Blitter emulator.
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


	machine MC68030
	
	include	"blitem/be_custom.i"



w_AFWM			equ	$04				;A first w mask
w_ALWM			equ	$06				;A last w mask
l_Pad0			equ	$08
l_Rows			equ	$0c				;Rows
l_Width			equ	$10				;Width
w_BShift		equ	$14				;B shift
w_AShift		equ	$16				;A shift
l_Pad1			equ	$18
s_Mintstore		equ	$1c				;4 lw mint storage
w_CRmod			equ	$2c				;C row mod
w_BRmod			equ	$2e				;B row mod
w_ARmod			equ	$30				;A row mod
w_DRmod			equ	$32				;D row mod
l_Pad2			equ	$34
w_Amod			equ	$38				;A mod (per access)
w_Bmod			equ	$3a				;B mod
w_Cmod			equ  	$3c				;C mod


OLDBLTHMAX		equ	64
BLTHMAX			equ	2048				;max blitter width
OLDBLTVMAX		equ	1024
BLTVMAX			equ	32768				;max blitter rows


	cnop	0,4

MintTrack:	dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0
		dc.l		0,0,0,0,0,0,0,0



	;
	;thin entry
	;
			
BlitEmThin:
		movem.l		d0-d7/a0-a6,-(sp)
		moveq		#$00,d5
		move.l		(fbl_BECustom,a6),a0
		move.w		(bec_bltsize,a0),d5
		move.l		d5,d6
		lsr.l		#$06,d5				;d5-Rows
		bne.s		th0				;--> >0
		
		move.l		#OLDBLTVMAX,d5
		
th0:		subq.l		#$01,d5
		move.l		d5,(l_Rows,a0)
		
		and.w		#$3f,d6				;d6-width
		beq.s		bs1				;-- >0
		
		moveq		#OLDBLTHMAX,d6				
		bra.s		bs1				;--> continue
	
	
	
	;
	;fat entry
	;
		
BlitEmFat:
		movem.l		d0-d7/a0-a6,-(sp)
		moveq		#$00,d5
		moveq		#$00,d6
		move.l		(fbl_BECustom,a6),a0
		move.w		(bec_bltsizv,a0),d5		;d5-Rows
		bne.s		bs0				;--> >0
		
		move.l		#BLTVMAX,d5
		
bs0:		subq.l		#$01,d5
		move.l		d5,(l_Rows,a0)
		
		move.w		(bec_bltsizh,a0),d6		;d6-Width (words)
		bne.s		bs1				;--> >0
		
		move.l		#BLTHMAX,d6
	
	
	
	
	;
	;main line, get pointers
	;
	
bs1:		move.l		d6,(l_Width,a0)

		moveq		#-2,d0
		moveq		#-2,d1
		and.l		(bec_bltcpt,a0),d0		;clean up addresses (no bytes)
		moveq		#-2,d2
		and.l		(bec_bltbpt,a0),d1
		moveq		#-2,d3
		and.l		(bec_bltapt,a0),d2
		moveq		#-2,d4
		and.l		(bec_bltdpt,a0),d3
		bclr		#$10,d4
		
		move.l		d2,a1				;a1-A
		move.l		d1,a2				;a2-B
		move.l		d0,a3				;a3-C
		move.l		d3,a4				;a4-D

		move.l		d4,d2				;kill mod bytes
		and.l		(bec_bltcmod,a0),d2
		and.l		(bec_bltamod,a0),d4
		move.l		d2,(w_CRmod,a0)
		move.l		d4,(w_ARmod,a0)


		
	;
	;mask stuff
	;
		
		move.l		(bec_bltafwm,a0),d5		;d5-fwm:lwm
		subq.w		#$01,d6
		bne.s		bs2				;--> >1 word wide
		
		move.l		d5,d0
		swap		d0
		and.l		d0,d5				;d5-fwm&lwm:fwm&lwm
		
bs2:		move.l		d5,(w_AFWM,a0)
				
				
				
	;
	;channels/mods etc
	;
									
		move.w		(bec_bltcon0,a0),d6		
		btst		#BBC0_DENA,d6
		beq		GoodExit			;--> D disabled, exit
		
		moveq		#$02,d0
		btst		#BBC0_AENA,d6
		bne.s		bs5				;--> A enabled
		
		moveq		#$00,d0				;no mod
		lea		(bec_bltadat,a0),a1		;point to data
		move.w		d0,(w_ARmod,a0)			;no row mod		
bs5:		move.w		d0,(w_Amod,a0)

		moveq		#$02,d0
		btst		#BBC0_BENA,d6
		bne.s		bs6				;--> B enabled
		
		moveq		#$00,d0				;no mod
		lea		(bec_bltbdat,a0),a2		;point to data
		move.w		d0,(w_BRmod,a0)		
bs6:		move.w		d0,(w_Bmod,a0)

		moveq		#$02,d0
		btst		#BBC0_CENA,d6
		bne.s		bs7				;--> C enabled
		
		moveq		#$00,d0				;no mod
		lea		(bec_bltcdat,a0),a3		;point to data
		move.w		d0,(w_CRmod,a0)		
bs7:		move.w		d0,(w_Cmod,a0)



	;
	;shift/minterm
	;	
				
		moveq		#$00,d1
		move.w		(bec_bltcon1,a0),d1		;set B shift
		lsl.l		#$04,d1				;d1-Bsh:xxxx
		
		move.b		d6,d0
		lea		(MintTrack,pc,d0.l),a5
		addq.b		#$01,(a5)

		add.b		d6,d6				;set mint
		subx.l		d5,d5
		add.b		d6,d6
		subx.w		d5,d5
		add.b		d6,d6
		subx.l		d4,d4
		add.b		d6,d6
		subx.w		d4,d4
		add.b		d6,d6
		subx.l		d3,d3
		add.b		d6,d6
		subx.w		d3,d3
		add.b		d6,d6
		subx.l		d2,d2
		add.b		d6,d6
		subx.w		d2,d2
		lsr.w		#$08,d6
		lsr.w		#$04,d6
		move.w		d6,d1				;d1-Bsh:Ash
		movem.l		d2-d5,(s_Mintstore,a0)
		move.l		d1,(w_BShift,a0)
		
	
		
	;
	;do stuff
	;		

		bsr.s		emuxa				;emulation
		
	
		
	;
	;update pointers
	;		
		
		move.l		a4,(bec_bltdpt,a0)
		move.w		(bec_bltcon0,a0),d6
		btst		#BBC0_AENA,d6
		beq.s		ups0				;--> A hasn't moved
		move.l		a1,(bec_bltapt,a0)
		
ups0:		btst		#BBC0_BENA,d6		
		beq.s		ups1				;--> B hasn't moved
		move.l		a2,(bec_bltbpt,a0)
		
ups1:		btst		#BBC0_CENA,d6
		beq.s		ups2				;--> C hasn't moved
		move.l		a3,(bec_bltcpt,a0)
		
ups2:		

GoodExit:	movem.l		(sp)+,d0-d7/a0-a6
		rts
		
		
	include	"blitem/blitters/emuxa.s"
		
	include	"blitem/blitters/emu16005.s"		
		
		
		