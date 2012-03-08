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
	= @Foldable fork: ForkTypeName* forkType "fork" Name forkName "{" Action* preActions ConditionalPath+ paths "}"
	| @Foldable namelessFork: ForkTypeName* forkType "fork" "{" Action* preActions ConditionalPath+ paths "}"
	| @Foldable chain: "chain" ChainName name "{" Action+ actions "}"
	;
	
syntax Action 
	= action: ActionName name ";"
	| chain: ChainName name ";"
	| definition: Definition definition
	;
	
syntax ConditionalPath 
	= @Foldable path: Expression expr "=\>" Action+ actions
	| @Foldable defaultPath: "default" "=\>" Action+ actions
	;

syntax Expression
	= single: Condition con
	| bracket "(" Expression expr ")"
	| negate: "not" Expression expr 
	> left and: Expression lhs "and" Expression rhs
	> left or: Expression lhs "or" Expression rhs
	;

start syntax Coordinator = coordinator: "Coordinator" Name name Invoke* invokes;

syntax Invoke = invoke: Name name "(" {ParameterValue ","}* params ")" ";"; 

syntax ParameterValue
	= normal: Number n
	| range: "[" Number rangeStart ".." Number rangeStop "]"
	;
lexical Number = @category="Constant" [0-9]+ !>> [0-9];