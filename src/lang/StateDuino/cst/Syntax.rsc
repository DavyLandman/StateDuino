module lang::StateDuino::cst::Syntax

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name StateTransitions* transitions;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: TypeName type ParamName name;
lexical ParamName = @category="Variable" Name;
lexical TypeName = @category="Type" Name;

lexical Name = ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]);

lexical ActionName = Name name;

lexical ForkName 
	= normalFork: Name name "?" 
	| sleepableFork: "#" Name name "?"
	| nonBlockingFork: "!" Name name "?"
	;
syntax StateTransitions
	= chain: {StateTransition "=\>"}+ transitions;
		
syntax StateTransition
	= action : ActionName action 
	| fork : ForkName name 
	| @Foldable forkDescription: ForkName name "{" ForkConditionTransitions+ transitions  "}" 
	; 
	
lexical ForkCondition = @category="MetaKeyword" ([a-zA-Z!] [a-zA-Z0-9_+\-!]* !>> [a-zA-Z0-9_+\-!]);

syntax ForkConditionTransitions
	= action: ForkCondition condition "=\>" StateTransitions transitions
	;