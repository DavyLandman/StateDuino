module lang::StateDuino::cst::stateduino

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name StateTransition* transitions;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: Name type Name name;

lexical Name = ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]) \ ForkAnswers;

keyword ForkAnswers = "yes" | "no" | "!";

lexical ActionName = Name name;

lexical ForkName 
	= normalFork: Name name "?" 
	| sleepableFork: "#" Name name "?"
	| nonBlockingFork: "!" Name name "?"
	;
	
syntax StateTransition
	= action : ActionName action 
	| fork : ForkName name 
	| forkDescription: ForkName name "{" ForkConditionTransitions+ transitions  "}"
	> left chain : StateTransition from "=\>" StateTransition to
	; 
	
syntax ForkConditionTransitions
	= action: ForkCondition condition StateTransition transitions
	;

syntax ForkCondition
	= yes: "yes" "=\>"
	| no: "no" "=\>"
	| always: "!" "=\>"
	;