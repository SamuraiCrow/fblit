


	IFND	BE_CUSTOM_I
	
BE_CUSTOM_I	SET	1

*
*	$VER: be_custom.i 0.01 (14.07.98)
*
*	Custom reg structure for BlitEm
*

bec_bltddat	EQU	$000				;D - data	(N/A)

		;note: space in here is used internally!

bec_bltcon0	EQU	$040				;bltcon0

		;bits 15-12	= A channel shift (to the right in ascending mode)
BBC0_ASH	EQU	$0c		

		;bits 11-8	= A,B,C,D Channel enable
BBC0_AENA	EQU	$0b
BBC0_BENA	EQU	$0a
BBC0_CENA	EQU	$09
BBC0_DENA	EQU	$08
		
		;bits 7-0	= Minterm (by bit)	- A,0,1,2,3 ~A,4,5,6,7
		;					- B,0,1,4,5 ~B,2,3,6,7
		;					- C,0,2,4,6 ~C,1,3,5,7
bec_minterm	EQU	$041							

bec_bltcon1	EQU	$042				;bltcon1

		;bits 15-12	= B channel shift
BBC1_BSH	EQU	$0c
		
		;bit  7		= D channel off				(N/A)
		;bit  4		= Exclusive fill enable			(N/A)
		;bit  3		= Inclusive fill enable			(N/A)
		;bit  2		= Fill carry input			(N/A)
		;bit  1		= Descending mode
BBC1_DESC	EQU	$01		
		;bit  0		= Line mode 				(N/A)
BBC1_LINE	EQU	$00		

bec_bltafwm	EQU	$044				;A - first word mask
bec_bltalwm	EQU	$046				;A - last word mask

bec_bltcpt	EQU	$048				;C - address
bec_bltbpt	EQU	$04C				;B - address
bec_bltapt	EQU	$050				;A - address
bec_bltdpt	EQU	$054				;D - address

bec_bltsize	EQU	$058				;blit size

bec_bltcon0l	EQU	$05B				;bltcon0	(N/A)

bec_bltsizv	EQU	$05C				;fat blit v size
bec_bltsizh	EQU	$05E				;fat blit h size

bec_bltcmod	EQU	$060				;C - modulo
bec_bltbmod	EQU	$062				;B - modulo
bec_bltamod	EQU	$064				;A - modulo
bec_bltdmod	EQU	$066				;D - modulo

bec_bltcdat	EQU	$070				;C - data
bec_bltbdat	EQU	$072				;B - data
bec_bltadat	EQU	$074				;A - data



bec_SIZEOF	EQU	$080


_LVOFatBlit	equ	-4
_LVOThinBlit	equ	-8

	ENDC  !BE_CUSTOM_I
