
#define reset(ch) d_step { do :: ch?_; :: empty(ch) -> break; od; skip }
#define reset3(ch) d_step { do :: ch?_,_,_; :: empty(ch) -> break; od; skip }
#define nondeterminism 1



mtype:ALU_ECC = {ALU_START_ecc, ALU_PositiveOp_ecc, ALU_NegativeOp_ecc};
proctype ALU(chan 
	EI_SUM, EI_DIFF, EO_CNF,
	VI_A, VI_B, VO_RES,
	alpha, beta
	) {
	int A = 0;
	int B = 0;
	int RES = 0;
	bit ExistsInputEvent = 0;
	bit ExistsEnabledECTran = 0;
	//mtype:OSM osm = s0_osm; 
	mtype:ALU_ECC Q = ALU_START_ecc;
	//int NA = 0;

	

  
  wait_events: 
  	end: // valid end state
	alpha?true;
	ExistsInputEvent = nempty(EI_SUM) || nempty(EI_DIFF);
	

	atomic {
		do
		:: nempty(VI_A) -> VI_A?A;
		:: nempty(VI_B) -> VI_B?B;
		:: empty(VI_A) && empty(VI_B) -> break;
		od 		
	}

  s0_osm: 
  	printf("ALU:s0_osm, Q=%d \n", Q); 
  	bit trans_START_PositiveOp, trans_START_NegativeOp, trans_NegativeOp_START, trans_PositiveOp_START;
  	
  	trans_START_PositiveOp = nempty(EI_SUM);
    trans_START_NegativeOp = nempty(EI_DIFF);
  	trans_NegativeOp_START = 1;
  	trans_PositiveOp_START = 1;

  	bit selectEI_SUM, selectEI_DIFF;
  	selectEI_SUM = nempty(EI_SUM);
  	selectEI_DIFF = !selectEI_SUM && nempty(EI_DIFF);
  

	// s0_osm select 1 event. Reset all other RuleSet1
	if
	:: atomic {selectEI_SUM ->
		EI_SUM?true;
	}
	:: atomic { selectEI_DIFF ->
		EI_DIFF?true;
	}
	:: (!ExistsInputEvent) -> goto done;
	:: else -> printf("ALU: no enabled transitions");
	fi

	// RuleSet1 reset all other inputs
	do 
	:: atomic { nempty(EI_SUM) -> EI_SUM?true;} 
	:: atomic { nempty(EI_DIFF) -> EI_DIFF?true;}
	:: else -> break; 
	od 
	goto s1_osm; // RuleSet3 


	s1_osm:
	ExistsEnabledECTran = (
		(Q == ALU_START_ecc && trans_START_PositiveOp && selectEI_SUM)
		|| (Q == ALU_START_ecc && trans_START_NegativeOp && selectEI_DIFF)
		|| (Q == ALU_PositiveOp_ecc && trans_NegativeOp_START)
		|| (Q == ALU_NegativeOp_ecc && trans_PositiveOp_START));

	printf("ALU:s1_osm EEC  %d \n", ExistsEnabledECTran); 


	atomic {
		if // RuleSet4: ECC transition. Conditions ordered
		:: (Q == ALU_START_ecc && trans_START_PositiveOp && selectEI_SUM) -> Q = ALU_PositiveOp_ecc;			
		:: (Q == ALU_START_ecc && trans_START_NegativeOp && selectEI_DIFF) -> Q = ALU_NegativeOp_ecc;
		:: (Q == ALU_PositiveOp_ecc && trans_NegativeOp_START) -> Q = ALU_START_ecc;
		:: (Q == ALU_NegativeOp_ecc && trans_PositiveOp_START) -> Q = ALU_START_ecc;
		:: !ExistsEnabledECTran -> goto done;
		:: else -> printf("ALU: No input events to process\n"); 
		fi;
		selectEI_SUM = 0;
		selectEI_DIFF = 0;
	}

	printf("ALU:s2_osm, Q=%d\n", Q); 
	s2_osm: //RuleSet6 tracks NI, don't needed. 
	atomic {
		if 
		:: (Q == ALU_START_ecc) -> skip;
		:: (Q == ALU_PositiveOp_ecc) -> 
			// action 1
			//algo
			RES = A + B; // RuleSet7 tracks change conditions for output variables. Don't needed.
			// NA := NA + 1; RuleSet5
			// action 2
			//emit event
			reset(VO_RES);
			reset(EO_CNF);	
			VO_RES!RES; // RuleSet9 change output data buffer.
			EO_CNF!true;  // RuleSet8 Emit Event 
		:: (Q == ALU_NegativeOp_ecc) -> 
			// action 1
			//algo
			RES = A - B; // RuleSet7 tracks change conditions for output variables. Don't needed.
			// NA := NA + 1; RuleSet5
			// action 2
			//emit event
			reset(VO_RES);
			reset(EO_CNF);	
			VO_RES!RES; // RuleSet9 change output data buffer.
			EO_CNF!true;  // RuleSet8 Emit Event 
		fi
	}
	
	goto s1_osm;



	
  done: // RuleSet10 
	beta!true;
	goto wait_events;
}

mtype:Performance15_dispatch = {ALU1_turn, ALU2_turn, ALU3_turn, ALU4_turn, ALU5_turn, ALU6_turn, ALU7_turn, ALU8_turn, ALU9_turn, ALU10_turn, ALU11_turn, ALU12_turn, ALU13_turn, ALU14_turn, ALU15_turn, DONE_turn_Performance15};
proctype Performance5(chan EI_REQ, EO_CNF, VO_RES, alpha, beta) {
	bit ExistsInputEvent = 0;
	mtype:Performance15_dispatch dispatch_state = ALU1_turn;
	bit omega;

	int RES;

	chan ALU1_EI_SUM = [1] of {bit};
	chan ALU1_EI_DIFF = [1] of {bit};
	chan ALU1_EO_CNF = [1] of {bit};
	chan ALU1_VI_A = [1] of {int};
	chan ALU1_VI_B = [1] of {int};
	chan ALU1_VO_RES = [1] of {int};
	chan ALU1_alpha = [0] of {bit};
	chan ALU1_beta = [0] of {bit};
	int buf_ALU1_RES;


	chan ALU2_EI_SUM = [1] of {bit};
	chan ALU2_EI_DIFF = [1] of {bit};
	chan ALU2_EO_CNF = [1] of {bit};
	chan ALU2_VI_A = [1] of {int};
	chan ALU2_VI_B = [1] of {int};
	chan ALU2_VO_RES = [1] of {int};
	chan ALU2_alpha = [0] of {bit};
	chan ALU2_beta = [0] of {bit};
	int buf_ALU2_RES;

	chan ALU3_EI_SUM = [1] of {bit};
	chan ALU3_EI_DIFF = [1] of {bit};
	chan ALU3_EO_CNF = [1] of {bit};
	chan ALU3_VI_A = [1] of {int};
	chan ALU3_VI_B = [1] of {int};
	chan ALU3_VO_RES = [1] of {int};
	chan ALU3_alpha = [0] of {bit};
	chan ALU3_beta = [0] of {bit};
	int buf_ALU3_RES;

	chan ALU4_EI_SUM = [1] of {bit};
	chan ALU4_EI_DIFF = [1] of {bit};
	chan ALU4_EO_CNF = [1] of {bit};
	chan ALU4_VI_A = [1] of {int};
	chan ALU4_VI_B = [1] of {int};
	chan ALU4_VO_RES = [1] of {int};
	chan ALU4_alpha = [0] of {bit};
	chan ALU4_beta = [0] of {bit};
	int buf_ALU4_RES;

	chan ALU5_EI_SUM = [1] of {bit};
	chan ALU5_EI_DIFF = [1] of {bit};
	chan ALU5_EO_CNF = [1] of {bit};
	chan ALU5_VI_A = [1] of {int};
	chan ALU5_VI_B = [1] of {int};
	chan ALU5_VO_RES = [1] of {int};
	chan ALU5_alpha = [0] of {bit};
	chan ALU5_beta = [0] of {bit};
	int buf_ALU5_RES;

	chan ALU6_EI_SUM = [1] of {bit};
	chan ALU6_EI_DIFF = [1] of {bit};
	chan ALU6_EO_CNF = [1] of {bit};
	chan ALU6_VI_A = [1] of {int};
	chan ALU6_VI_B = [1] of {int};
	chan ALU6_VO_RES = [1] of {int};
	chan ALU6_alpha = [0] of {bit};
	chan ALU6_beta = [0] of {bit};
	int buf_ALU6_RES;

	chan ALU7_EI_SUM = [1] of {bit};
	chan ALU7_EI_DIFF = [1] of {bit};
	chan ALU7_EO_CNF = [1] of {bit};
	chan ALU7_VI_A = [1] of {int};
	chan ALU7_VI_B = [1] of {int};
	chan ALU7_VO_RES = [1] of {int};
	chan ALU7_alpha = [0] of {bit};
	chan ALU7_beta = [0] of {bit};
	int buf_ALU7_RES;

	chan ALU8_EI_SUM = [1] of {bit};
	chan ALU8_EI_DIFF = [1] of {bit};
	chan ALU8_EO_CNF = [1] of {bit};
	chan ALU8_VI_A = [1] of {int};
	chan ALU8_VI_B = [1] of {int};
	chan ALU8_VO_RES = [1] of {int};
	chan ALU8_alpha = [0] of {bit};
	chan ALU8_beta = [0] of {bit};
	int buf_ALU8_RES;

	chan ALU9_EI_SUM = [1] of {bit};
	chan ALU9_EI_DIFF = [1] of {bit};
	chan ALU9_EO_CNF = [1] of {bit};
	chan ALU9_VI_A = [1] of {int};
	chan ALU9_VI_B = [1] of {int};
	chan ALU9_VO_RES = [1] of {int};
	chan ALU9_alpha = [0] of {bit};
	chan ALU9_beta = [0] of {bit};
	int buf_ALU9_RES;

	chan ALU10_EI_SUM = [1] of {bit};
	chan ALU10_EI_DIFF = [1] of {bit};
	chan ALU10_EO_CNF = [1] of {bit};
	chan ALU10_VI_A = [1] of {int};
	chan ALU10_VI_B = [1] of {int};
	chan ALU10_VO_RES = [1] of {int};
	chan ALU10_alpha = [0] of {bit};
	chan ALU10_beta = [0] of {bit};
	int buf_ALU10_RES;

	chan ALU11_EI_SUM = [1] of {bit};
	chan ALU11_EI_DIFF = [1] of {bit};
	chan ALU11_EO_CNF = [1] of {bit};
	chan ALU11_VI_A = [1] of {int};
	chan ALU11_VI_B = [1] of {int};
	chan ALU11_VO_RES = [1] of {int};
	chan ALU11_alpha = [0] of {bit};
	chan ALU11_beta = [0] of {bit};
	int buf_ALU11_RES;

	chan ALU12_EI_SUM = [1] of {bit};
	chan ALU12_EI_DIFF = [1] of {bit};
	chan ALU12_EO_CNF = [1] of {bit};
	chan ALU12_VI_A = [1] of {int};
	chan ALU12_VI_B = [1] of {int};
	chan ALU12_VO_RES = [1] of {int};
	chan ALU12_alpha = [0] of {bit};
	chan ALU12_beta = [0] of {bit};
	int buf_ALU12_RES;

	chan ALU13_EI_SUM = [1] of {bit};
	chan ALU13_EI_DIFF = [1] of {bit};
	chan ALU13_EO_CNF = [1] of {bit};
	chan ALU13_VI_A = [1] of {int};
	chan ALU13_VI_B = [1] of {int};
	chan ALU13_VO_RES = [1] of {int};
	chan ALU13_alpha = [0] of {bit};
	chan ALU13_beta = [0] of {bit};
	int buf_ALU13_RES;

	chan ALU14_EI_SUM = [1] of {bit};
	chan ALU14_EI_DIFF = [1] of {bit};
	chan ALU14_EO_CNF = [1] of {bit};
	chan ALU14_VI_A = [1] of {int};
	chan ALU14_VI_B = [1] of {int};
	chan ALU14_VO_RES = [1] of {int};
	chan ALU14_alpha = [0] of {bit};
	chan ALU14_beta = [0] of {bit};
	int buf_ALU14_RES;

	chan ALU15_EI_SUM = [1] of {bit};
	chan ALU15_EI_DIFF = [1] of {bit};
	chan ALU15_EO_CNF = [1] of {bit};
	chan ALU15_VI_A = [1] of {int};
	chan ALU15_VI_B = [1] of {int};
	chan ALU15_VO_RES = [1] of {int};
	chan ALU15_alpha = [0] of {bit};
	chan ALU15_beta = [0] of {bit};
	int buf_ALU15_RES;


	atomic {
	 run ALU(ALU1_EI_SUM, ALU1_EI_DIFF, ALU1_EO_CNF, ALU1_VI_A, ALU1_VI_B, ALU1_VO_RES, ALU1_alpha, ALU1_beta);
	 run ALU(ALU2_EI_SUM, ALU2_EI_DIFF, ALU2_EO_CNF, ALU2_VI_A, ALU2_VI_B, ALU2_VO_RES, ALU2_alpha, ALU2_beta);
	 run ALU(ALU3_EI_SUM, ALU3_EI_DIFF, ALU3_EO_CNF, ALU3_VI_A, ALU3_VI_B, ALU3_VO_RES, ALU3_alpha, ALU3_beta);
	 run ALU(ALU4_EI_SUM, ALU4_EI_DIFF, ALU4_EO_CNF, ALU4_VI_A, ALU4_VI_B, ALU4_VO_RES, ALU4_alpha, ALU4_beta);
	 run ALU(ALU5_EI_SUM, ALU5_EI_DIFF, ALU5_EO_CNF, ALU5_VI_A, ALU5_VI_B, ALU5_VO_RES, ALU5_alpha, ALU5_beta);
	 run ALU(ALU6_EI_SUM, ALU6_EI_DIFF, ALU6_EO_CNF, ALU6_VI_A, ALU6_VI_B, ALU6_VO_RES, ALU6_alpha, ALU6_beta);
	 run ALU(ALU7_EI_SUM, ALU7_EI_DIFF, ALU7_EO_CNF, ALU7_VI_A, ALU7_VI_B, ALU7_VO_RES, ALU7_alpha, ALU7_beta);
	 run ALU(ALU8_EI_SUM, ALU8_EI_DIFF, ALU8_EO_CNF, ALU8_VI_A, ALU8_VI_B, ALU8_VO_RES, ALU8_alpha, ALU8_beta);
	 run ALU(ALU9_EI_SUM, ALU9_EI_DIFF, ALU9_EO_CNF, ALU9_VI_A, ALU9_VI_B, ALU9_VO_RES, ALU9_alpha, ALU9_beta);
	 run ALU(ALU10_EI_SUM, ALU10_EI_DIFF, ALU10_EO_CNF, ALU10_VI_A, ALU10_VI_B, ALU10_VO_RES, ALU10_alpha, ALU10_beta);
	 run ALU(ALU11_EI_SUM, ALU11_EI_DIFF, ALU11_EO_CNF, ALU11_VI_A, ALU11_VI_B, ALU11_VO_RES, ALU11_alpha, ALU11_beta);
	 run ALU(ALU12_EI_SUM, ALU12_EI_DIFF, ALU12_EO_CNF, ALU12_VI_A, ALU12_VI_B, ALU12_VO_RES, ALU12_alpha, ALU12_beta);
	 run ALU(ALU13_EI_SUM, ALU13_EI_DIFF, ALU13_EO_CNF, ALU13_VI_A, ALU13_VI_B, ALU13_VO_RES, ALU13_alpha, ALU13_beta);
	 run ALU(ALU14_EI_SUM, ALU14_EI_DIFF, ALU14_EO_CNF, ALU14_VI_A, ALU14_VI_B, ALU14_VO_RES, ALU14_alpha, ALU14_beta);
	 run ALU(ALU15_EI_SUM, ALU15_EI_DIFF, ALU15_EO_CNF, ALU15_VI_A, ALU15_VI_B, ALU15_VO_RES, ALU15_alpha, ALU15_beta);
	}

   wait_events: 
	end: 
	alpha?true;
	dispatch_state = ALU1_turn;

   read_input_events: 
   	ExistsInputEvent = nempty(EI_REQ);

   	if
   	:: d_step { nempty(EI_REQ) -> 
   		reset(ALU1_EI_SUM);
   		ALU1_EI_SUM!true;
   		ALU1_VI_A!1;
   		ALU1_VI_B!0;
   	} 
   	:: (!ExistsInputEvent) -> skip;
   	fi

   dispatch: 
   	if 
   	:: atomic { dispatch_state == ALU1_turn -> 
   		ALU1_alpha!true;
   		ALU1_beta?true;
   		dispatch_state = ALU2_turn;
   	}
   	:: atomic { dispatch_state == ALU2_turn -> 
   		ALU2_alpha!true;
   		ALU2_beta?true;
   		dispatch_state = ALU3_turn;
   	}
   	:: atomic { dispatch_state == ALU3_turn -> 
   		ALU3_alpha!true;
   		ALU3_beta?true;
   		dispatch_state = ALU4_turn;
   	}
   	:: atomic { dispatch_state == ALU4_turn -> 
   		ALU4_alpha!true;
   		ALU4_beta?true;
   		dispatch_state = ALU5_turn;
   	}
   	:: atomic { dispatch_state == ALU5_turn -> 
   		ALU5_alpha!true;
   		ALU5_beta?true;
   		dispatch_state = ALU6_turn;
   	}
   	:: atomic { dispatch_state == ALU6_turn -> 
   		ALU6_alpha!true;
   		ALU6_beta?true;
   		dispatch_state = ALU7_turn;
   	}
   	:: atomic { dispatch_state == ALU7_turn -> 
   		ALU7_alpha!true;
   		ALU7_beta?true;
   		dispatch_state = ALU8_turn;
   	}
   	:: atomic { dispatch_state == ALU8_turn -> 
   		ALU8_alpha!true;
   		ALU8_beta?true;
   		dispatch_state = ALU9_turn;
   	}
   	:: atomic { dispatch_state == ALU9_turn -> 
   		ALU9_alpha!true;
   		ALU9_beta?true;
   		dispatch_state = ALU10_turn;
   	}
   	:: atomic { dispatch_state == ALU10_turn -> 
   		ALU10_alpha!true;
   		ALU10_beta?true;
   		dispatch_state = ALU11_turn;
   	}
   	:: atomic { dispatch_state == ALU11_turn -> 
   		ALU11_alpha!true;
   		ALU11_beta?true;
   		dispatch_state = ALU12_turn;
   	}
   	:: atomic { dispatch_state == ALU12_turn -> 
   		ALU12_alpha!true;
   		ALU12_beta?true;
   		dispatch_state = ALU13_turn;
   	}
   	:: atomic { dispatch_state == ALU13_turn -> 
   		ALU13_alpha!true;
   		ALU13_beta?true;
   		dispatch_state = ALU14_turn;
   	}
   	:: atomic { dispatch_state == ALU14_turn -> 
   		ALU14_alpha!true;
   		ALU14_beta?true;
   		dispatch_state = ALU15_turn;
   	}
   	:: atomic { dispatch_state == ALU15_turn -> 
   		ALU15_alpha!true;
   		ALU15_beta?true;
   		dispatch_state = DONE_turn_Performance15;
   	}
   	:: dispatch_state == DONE_turn_Performance15 -> skip;
   	fi

   	goto read_component_event_outputs;

   read_component_event_outputs:
   	atomic {
   		omega = empty(ALU1_EO_CNF) && empty(ALU2_EO_CNF) && empty(ALU3_EO_CNF) && empty(ALU4_EO_CNF) && empty(ALU5_EO_CNF) && empty(ALU6_EO_CNF) && empty(ALU7_EO_CNF) && empty(ALU8_EO_CNF) && empty(ALU9_EO_CNF)  && empty(ALU10_EO_CNF)  && empty(ALU11_EO_CNF)  && empty(ALU12_EO_CNF)  && empty(ALU13_EO_CNF)  && empty(ALU14_EO_CNF) && empty(ALU15_EO_CNF);

   		if
   		:: nempty(ALU1_EO_CNF) -> 
   			ALU1_EO_CNF?true;
   			ALU1_VO_RES?buf_ALU1_RES;

   			reset(ALU2_EI_SUM);
   			reset(ALU2_VI_A);
   			reset(ALU2_VI_B);
   			ALU2_EI_SUM!true;
   			ALU2_VI_A!buf_ALU1_RES;
   			ALU2_VI_B!1;

   		:: nempty(ALU2_EO_CNF) -> 
   			ALU2_EO_CNF?true;
   			ALU2_VO_RES?buf_ALU2_RES;

   			reset(ALU3_EI_SUM);
   			reset(ALU3_VI_A);
   			reset(ALU3_VI_B);
   			ALU3_EI_SUM!true;
   			ALU3_VI_A!buf_ALU2_RES;
   			ALU3_VI_B!1;
   		:: nempty(ALU3_EO_CNF) -> 
   			ALU3_EO_CNF?true;
   			ALU3_VO_RES?buf_ALU3_RES;

   			reset(ALU4_EI_SUM);
   			reset(ALU4_VI_A);
   			reset(ALU4_VI_B);
   			ALU4_EI_SUM!true;
   			ALU4_VI_A!buf_ALU3_RES;
   			ALU4_VI_B!1;

   		:: nempty(ALU4_EO_CNF) -> 
   			ALU4_EO_CNF?true;
   			ALU4_VO_RES?buf_ALU4_RES;

   			reset(ALU5_EI_SUM);
   			reset(ALU5_VI_A);
   			reset(ALU5_VI_B);
   			ALU5_EI_SUM!true;
   			ALU5_VI_A!buf_ALU4_RES;
   			ALU5_VI_B!1;
   		:: nempty(ALU5_EO_CNF) -> 
   			ALU5_EO_CNF?true;
   			ALU5_VO_RES?buf_ALU5_RES;

   			reset(ALU6_EI_SUM);
   			reset(ALU6_VI_A);
   			reset(ALU6_VI_B);
   			ALU6_EI_SUM!true;
   			ALU6_VI_A!buf_ALU5_RES;
   			ALU6_VI_B!1;
   		:: nempty(ALU6_EO_CNF) -> 
   			ALU6_EO_CNF?true;
   			ALU6_VO_RES?buf_ALU6_RES;

   			reset(ALU7_EI_SUM);
   			reset(ALU7_VI_A);
   			reset(ALU7_VI_B);
   			ALU7_EI_SUM!true;
   			ALU7_VI_A!buf_ALU6_RES;
   			ALU7_VI_B!1;
   		:: nempty(ALU7_EO_CNF) -> 
   			ALU7_EO_CNF?true;
   			ALU7_VO_RES?buf_ALU7_RES;

   			reset(ALU8_EI_SUM);
   			reset(ALU8_VI_A);
   			reset(ALU8_VI_B);
   			ALU8_EI_SUM!true;
   			ALU8_VI_A!buf_ALU7_RES;
   			ALU8_VI_B!1;
   		:: nempty(ALU8_EO_CNF) -> 
   			ALU8_EO_CNF?true;
   			ALU8_VO_RES?buf_ALU8_RES;

   			reset(ALU9_EI_SUM);
   			reset(ALU9_VI_A);
   			reset(ALU9_VI_B);
   			ALU9_EI_SUM!true;
   			ALU9_VI_A!buf_ALU8_RES;
   			ALU9_VI_B!1;
   		:: nempty(ALU9_EO_CNF) -> 
   			ALU9_EO_CNF?true;
   			ALU9_VO_RES?buf_ALU9_RES;

   			reset(ALU10_EI_SUM);
   			reset(ALU10_VI_A);
   			reset(ALU10_VI_B);
   			ALU10_EI_SUM!true;
   			ALU10_VI_A!buf_ALU9_RES;
   			ALU10_VI_B!1;
   		:: nempty(ALU10_EO_CNF) -> 
   			ALU10_EO_CNF?true;
   			ALU10_VO_RES?buf_ALU10_RES;

   			reset(ALU11_EI_SUM);
   			reset(ALU11_VI_A);
   			reset(ALU11_VI_B);
   			ALU11_EI_SUM!true;
   			ALU11_VI_A!buf_ALU10_RES;
   			ALU11_VI_B!1;

   		:: nempty(ALU11_EO_CNF) -> 
   			ALU11_EO_CNF?true;
   			ALU11_VO_RES?buf_ALU11_RES;

   			reset(ALU12_EI_SUM);
   			reset(ALU12_VI_A);
   			reset(ALU12_VI_B);
   			ALU12_EI_SUM!true;
   			ALU12_VI_A!buf_ALU11_RES;
   			ALU12_VI_B!1;
   		:: nempty(ALU12_EO_CNF) -> 
   			ALU12_EO_CNF?true;
   			ALU12_VO_RES?buf_ALU12_RES;

   			reset(ALU13_EI_SUM);
   			reset(ALU13_VI_A);
   			reset(ALU13_VI_B);
   			ALU13_EI_SUM!true;
   			ALU13_VI_A!buf_ALU12_RES;
   			ALU13_VI_B!1;
   		:: nempty(ALU13_EO_CNF) -> 
   			ALU13_EO_CNF?true;
   			ALU13_VO_RES?buf_ALU13_RES;

   			reset(ALU14_EI_SUM);
   			reset(ALU14_VI_A);
   			reset(ALU14_VI_B);
   			ALU14_EI_SUM!true;
   			ALU14_VI_A!buf_ALU13_RES;
   			ALU14_VI_B!1;
   		:: nempty(ALU14_EO_CNF) -> 
   			ALU14_EO_CNF?true;
   			ALU14_VO_RES?buf_ALU14_RES;

   			reset(ALU15_EI_SUM);
   			reset(ALU15_VI_A);
   			reset(ALU15_VI_B);
   			ALU15_EI_SUM!true;
   			ALU15_VI_A!buf_ALU14_RES;
   			ALU15_VI_B!1;
   		:: nempty(ALU15_EO_CNF) -> 
   			ALU15_EO_CNF?true;
   			ALU15_VO_RES?buf_ALU15_RES;

   			reset(EO_CNF);
   			reset(VO_RES);
   			EO_CNF!true;
   			VO_RES!buf_ALU15_RES;

   		:: (omega && dispatch_state == DONE_turn_Performance15) -> goto done;
   		:: (omega && dispatch_state != DONE_turn_Performance15) -> goto dispatch; 
   		fi
   	}
   	goto read_component_event_outputs;

   done: 
   	atomic {
   		beta!true;
   		// phi var
   	}
   	goto wait_events;

}

int res;
bit complete = 0;

init {
	int lastpid;

	chan EI_REQ = [1] of {bit};
	chan EO_CNF = [1] of {bit};
	chan VO_RES = [1] of {int};
	chan alpha = [0] of {bit};
	chan beta = [0] of {bit};

	atomic {
		run Performance5(EI_REQ, EO_CNF, VO_RES, alpha, beta);
		EI_REQ!true;
	}

   dispatch: 
	alpha!true;
	beta?true;
	
	EO_CNF?true;
	VO_RES?res;
	

	printf("Result: %d\n", res);
	complete = 1;
}


ltl p1 {[](<>(complete && res == 15))}
