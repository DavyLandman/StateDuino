module lang::StateDuino::cst::stateduino

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = "StateMachine" StateMachineIdentifier StateTransition* transitions;

syntax StateMachineIdentifier 
	= normalStateMachine: Name name
	| parameterizedStateMachine: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = Type type Name name;

lexical Name = ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]) \ ForkAnswers;

keyword Type = "int" | "bool";
keyword ForkAnswers = "yes" | "no" | "#";
keyword ImportantMarkings = "!" | "?" | "=\>";

lexical ActionName = Name name !>> "?";

lexical ForkName 
	= normalFork: "!" !<< Name name "?" !>> "?"
	| nonBlockingFork: "!" Name name "?" !>> "?"
	;
syntax StateTransition
	= actionChain : ActionName from "=\>" StateTransition to
	| forkDescription: ForkName name "{" ForkConditionTransitions+ transitions  "}"
	> singleAction : ActionName state 
	> singleFork : ForkName fork 
	; 
	
syntax ForkConditionTransitions
	= action: ForkCondition answer StateTransition transitions
	| sleepableLoop: ForkCondition answer "#"
	;

syntax ForkCondition
	= yes: "yes" "=\>"
	| no: "no" "=\>"
	| always: "!" "=\>"
	;