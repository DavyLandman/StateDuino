module lang::StateDuino::cst::Syntax

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name
	"start" "=" ForkName startFork 
	Definition* definitions ;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: TypeName type ParamName name;
lexical ParamName = @category="Variable" Name;
lexical TypeName = @category="Type" Name;

lexical Name = ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]);

lexical ActionName = Name name;
lexical ChainName = @category="Chain" "_" Name name;
lexical ForkName = Name name;
lexical ForkTypeName = @category="MetaKeyword" Name nam;
lexical Condition = Name name "?";


syntax Definition 
	= @Foldable forkDefinition: ForkTypeName* forkType "fork" Name forkName ForkBody body
	| @Foldable namelessForkDefinition: ForkTypeName* forkType "fork" ForkBody body
	| @Foldable chainDefinition: "chain" ChainName name "{" Action+ actions "}"
	;
	
syntax ForkBody = body: "{" 
		Action* preActions
		ConditionalPath+ paths
	"}";
	
syntax Action 
	= action: ActionName name ";"
	| chain: ChainName name ";"
	| definition: Definition definition
	;
	
syntax ConditionalPath 
	= @Foldable path: ConditionalExpression expr "=\>" Action+ actions
	| @Foldable defaultPath: "default" "=\>" Action+ actions
	;

syntax ConditionalExpression
	= single: Condition con
	| not: "not" Condition con
	| and: ConditionalExpression lhs "&&" ConditionalExpression rhs
	| or: ConditionalExpression lhs "||" ConditionalExpression rhs
	| bracket "(" ConditionalExpression con ")"
	;

/*
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
	
	
start syntax Coordinator = coordinator: "Coordinator" Name name Invoke* invokes;

syntax Invoke = invoke: Name name "(" {ParameterValue ","}* params ")" ";"; 

syntax ParameterValue
	= normal: Number n
	| range: "[" Number rangeStart ".." Number rangeStop "]"
	;
lexical Number = @category="Constant" [0-9]+ !>> [0-9];
*/