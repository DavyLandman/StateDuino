module lang::StateDuino::ast::Main

data StateMachine = stateMachine(StateMachineIdentifier name,  str startFork, list[Definition] definitions);

data StateMachineIdentifier 
	= normal(str name)
	| parameterized(str name, list[Parameter] params)
	;

data Parameter = param(str \type, str name);

data Definition 
	= fork(list[str] forkType, str name, list[Action] preActions, list[ConditionalPath] paths)
	| namelessFork(list[str] forkType, list[Action] preActions, list[ConditionalPath] paths)
	| chain(str name, list[Action] actions)
	;
	
data Action
	= action(str name)
	| definition(Definition definition)
	;
	
data ConditionalPath
	= path(Expression expr, list[Action] actions)
	| defaultPath(list[Action] actions)
	;
	
data Expression
	= single(str con)
	| negate(Expression expr)
	| and(Expression lhs, Expression rhs)
	| or(Expression lhs, Expression rhs)
	;
	
	
data Coordinator = coordinator(str name, list[Invoke] invokes);

data Invoke = invoke(str name, list[ParameterValue] params);

data ParameterValue
	= normal(int number)
	| range(int startRange, int stopRange)
	;
	
anno loc StateMachine@location;
anno loc StateMachineIdentifier@location;
anno loc Parameter@location;
anno loc Definition@location;
anno loc Action@location;
anno loc ConditionalPath@location;
anno loc Expression@location;
anno loc Coordinator@location;
anno loc Invoke@location;
anno loc ParameterValue@location;