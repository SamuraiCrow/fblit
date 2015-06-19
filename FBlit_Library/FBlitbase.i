




	IFND    EXEC_LISTS_I
		include 'exec/lists.i'
	ENDC
	
	IFND    EXEC_LIBRARIES_I
		include 'exec/libraries.i'
	ENDC




FB_JAM2			equ		0			;JAM2 (=RP_JAM2)
FB_COMPLEMENT		equ		1			;complement flag (=RP_COMPLEMENT)
FB_INVERSVID		equ		2			;inverse video (=RP_INVERSVID)

FB_FRST_DOT		equ		0			;frst_dot
FB_ONE_DOT		equ		1			;one_dot



BEC_SIZEOF		equ		$1000			;size of blitem custom 
LASTCHANCE_SIZEOF	equ		$10000			;size of last chance
MINSTACK		equ		$200			;min stack
BOBBUF_SIZEOF		equ		$80000			;size of BOB buffer


	STRUCTURE	fblbase,LIB_SIZE
	
		ULONG	fbl_SegList
		APTR	fbl_ExecBase
		APTR	fbl_LayersBase
		APTR	fbl_GraphicsBase
		ULONG	fbl_ChipMax			;top of chip mem
		APTR	fbl_BECustom			;BlitEm custom structure
		APTR	fbl_LastChance			;last change memory
		APTR	fbl_LCSemaphore			;last chance arbitration semaphore
		ULONG	fbl_MinStack			;min stack size
		APTR	fbl_UtilityBase
		APTR	fbl_IntuitionBase
		
		;add/rembob stuff
		APTR	fbl_BOBSem			;buffer arbitration
		APTR	fbl_BOBBuf			;*BOB buffer
		ULONG	fbl_BOBCnt			;BOB counter
		
	LABEL		fblbase_SIZEOF


