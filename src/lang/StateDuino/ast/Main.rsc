module lang::StateDuino::ast::Main

data StateMachine = stateMachine(StateMachineIdentifier name, Name startFork, list[Definition] definitions);

data Name = name(str name);

data StateMachineIdentifier 
	= normal(Name name)
	| parameterized(Name name, list[Parameter] params)
	;

data ForkType = sleepable() | immediate();

data Parameter = param(Name \type, Name name);

data Definition 
	= fork(list[ForkType] forkType, Name name, list[Action] preActions, list[ConditionalPath] paths)
	| namelessFork(list[ForkType] forkType, list[Action] preActions, list[ConditionalPath] paths)
	| chain(Name name, list[Action] actions)
	;
	
data Action
	= action(Name name)
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
	
	
data Coordinator = coordinator(Name name, list[Invoke] invokes);

data Invoke = invoke(Name name, list[int] params);
	
anno loc StateMachine@location;
anno loc StateMachineIdentifier@location;
anno loc Parameter@location;
anno loc Definition@location;
anno loc Action@location;
anno loc ConditionalPath@location;
anno loc Expression@location;
anno loc Coordinator@location;
anno loc Invoke@location;
anno loc Name@location;