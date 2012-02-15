module lang::StateDuino::cst::stateduino

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name StateTransition* transitions;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: TypeName type ParamName name;
lexical ParamName = @category="MetaVariable" Name;
lexical TypeName = @category="Type" Name;

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
	| @Foldable forkDescription: ForkName name "{" ForkConditionTransitions+ transitions  "}" 
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