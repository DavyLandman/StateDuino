module lang::StateDuino::cst::stateduino

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name StateTransition* transitions;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: Type type Name name;

lexical Name = ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]) \ ForkAnswers;

keyword Type = "int" | "bool";
keyword ForkAnswers = "yes" | "no" | "#";
keyword ImportantMarkings = "!" | "?" | "=\>";

lexical ActionName = Name name;

lexical ForkName 
	= normalFork: /*"!" !<<*/ Name name "?" 
	| nonBlockingFork: "!" Name name "?"
	;
	
syntax StateTransition
	= actionChain : ActionName from "=\>" StateTransition to
	| forkDescription: ForkName name "{" ForkConditionTransitions+ transitions  "}"
	> singleAction : ActionName action 
	> singleFork : ForkName name 
	; 
	
syntax ForkConditionTransitions
	= action: ForkCondition condition StateTransition transitions
	| sleepableLoop: ForkCondition answer "#"
	;

syntax ForkCondition
	= yes: "yes" "=\>"
	| no: "no" "=\>"
	| always: "!" "=\>"
	;