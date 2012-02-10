module lang::StateDuino::cst::stateduino

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = "StateMachine" StateMachineIdentifier StateTransition* transitions;

syntax StateMachineIdentifier 
	= normalStateMachine: Name name
	| parameterizedStateMachine: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = Type type Name name;

lexical Name = [a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-] \ ForkAnswers;

keyword Type = "int" | "bool";
keyword ForkAnswers = "yes" | "no";
keyword ImportantMarkings = "!" | "?" | "=\>";

lexical StateName = Name name !>> "?";

lexical ForkName 
	= normalFork: "!" !<< Name name "?" !>> "?"
	| nonBlockingFork: "!" Name name "?" !>> "?"
	;

syntax StateTransition
	= startState : StateName fromState "=\>" StateTransition toStateTransition
	| forkDescription: ForkName ForkAnswerTransition+ forkAnswers
	> singleState : StateName state !>> "=\>"
	> singleFork : ForkName fork !>> "yes"
	; 
	
syntax ForkAnswerTransition = ForkAnswer answer StateTransition transitions;

lexical ForkAnswer 
	= yes: [\ \t] !<< [\ \t]+ !>> [\ \t] indent "yes" [\ \t]* "=\>"
	| no: [\ \t] !<< [\ \t]+ !>> [\ \t] indent "no" [\ \t]* "=\>"
	;
	
