module lang::StateDuino::cst::Syntax

extend lang::std::Layout; // get comments and spaces layout for free

start syntax StateMachine = stateMachine: "StateMachine" StateMachineIdentifier name
	"start" "=" Name startFork 
	Definition* definitions ;

syntax StateMachineIdentifier 
	= normal: Name name
	| parameterized: Name name "(" {Parameter ","}+ params")"
	;
	
syntax Parameter = param: Name type Name name;
/*
lexical ParamName = @category="Variable" Name;
lexical TypeName = @category="Type" Name;
*/

lexical Name = name: ([a-zA-Z] [a-zA-Z0-9_+\-]* !>> [a-zA-Z0-9_+\-]);

lexical Condition = Name name "?";
syntax ForkType 
	= sleepable: "sleepable"
	| immediate: "immediate"
	;

keyword ForkTypeKeyword = ForkType tp; 

syntax Definition 
	= @Foldable fork: ForkType* forkType "fork" Name forkName "{" Action* preActions ConditionalPath* paths "}"
	| @Foldable namelessFork: ForkType* forkType "fork" "{" Action* preActions ConditionalPath* paths "}"
	| @Foldable chain: "chain" Name name "{" Action* actions "}"
	;
	
syntax Action 
	= action: Name name ";"
	| definition: Definition definition
	;
	
syntax ConditionalPath 
	= @Foldable path: Expression expr "=\>" Action* actions
	| @Foldable defaultPath: "default" "=\>" Action* actions
	;

syntax Expression
	= single: Condition con
	| bracket "(" Expression expr ")"
	| negate: "not" Expression expr 
	> left and: Expression lhs "and" Expression rhs
	> left or: Expression lhs "or" Expression rhs
	;

start syntax Coordinator = coordinator: "Coordinator" Name name Invoke* invokes;

syntax Invoke = invoke: Name name "(" {Number ","}* params ")" ";"; 

lexical Number = @category="Constant" [0-9]+ !>> [0-9];