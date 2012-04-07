module lang::StateDuino::builders::C

import IO;
import List;
import String;

import lang::StateDuino::ast::Full;
import lang::StateDuino::ast::Main;
import lang::StateDuino::transformations::Simplify;
import lang::StateDuino::semantics::Checker;

public void writeStateMachine(loc directory, loc coordinator) {
	<coor, machines> = loadFullStateMachine(coordinator);
	checkForErrors(machines);
	machines = {simplify(m) | m <- machines};
	for (m <- machines) {
		writeStateMachine(directory, m);	
	}
	writeCoordinator(directory, coor);
}

private void checkForErrors(set[StateMachine] machines) {
	set[Message] errors = {};
	for (sm <- machines) {
		errors += performStructuralCheck(sm);
	}
	if (errors != {}) {
		throw "One or more errors in the state machines: <errors>";
	}
}

private void writeStateMachine(loc directory, StateMachine sm) {
	loc hFile = directory[file="<sm.name.name>.h"];
	loc cFile = directory[file="<sm.name.name>.c"];
	loc hSMFile = directory[file="_SM<sm.name.name>.h"];
	loc cSMFile = directory[file="_SM<sm.name.name>.c"];
	writeStateMachineHeader(hSMFile, sm);
	writeStateMachineImplementation(cSMFile, sm);
	writeCallbackHeader(hFile, sm);
	if (!exists(cFile)) {
		writeDefaultCallback(cFile, sm);	
	}
}
private void writeCoordinator(loc directory, Coordinator coor) {
	loc hFile = directory[file="<coor.name>.h"];
	loc cFile = directory[file="<coor.name>.c"];
	loc hSharedStateFile = directory[file="SharedState.h"];
	writeCoordinatorHeader(hFile, coor);
	writeCoordinatorImplementation(cFile, coor);
	if (!exists(hSharedStateFile)) {
		writeStartSharedStateFile(hSharedStateFile);	
	}
}

private void writeStartSharedStateFile(loc f) {
	writeFile(f, cleanup("#ifndef SHAREDSTATE_H
		'#define SHAREDSTATE_H
		'#ifdef __cplusplus
		'extern \"C\"{
		'#endif	
		'//add your own fields to the struct 
		'typedef struct {
		'	
		'} SharedStateInfo;
		'typedef SharedStateInfo* SharedState;
		'#ifdef __cplusplus
		'}
		'#endif	
		'#endif
		"));
}

private void writeCoordinatorHeader(loc f, Coordinator coor) {
	writeFile(f, cleanup("#ifndef <toUpperCase(coor.name)>_H
	'#define <toUpperCase(coor.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h
	'****************************************/
	'#include \"SharedState.h\"
	'<for(inv <- sort([*{n | invoke(n, _) <- coor.invokes}])) {>
		'#include \"_SM<inv>.h\"
	'<}>
	'#include \<stdint.h\>
	'#ifdef __cplusplus
	'extern \"C\"{
	'#endif	
	
	'void <coor.name>_initialize(SharedState state);
	'void <coor.name>_performStep();
	'int8_t <coor.name>_canSleep();
	
	'#ifdef __cplusplus
	'}
	'#endif
	'#endif
	"));
}
private void writeCoordinatorImplementation(loc f, Coordinator coor) {
	list[tuple[str, str, str]] invokes = [
		<n,	
			size(ps) > 0 ? n + ("<head(ps)>" | "<it>_<p>" | p <- tail(ps)) : n, 
			size(ps) > 0 ? (", <head(ps)>" | "<it>, <p>" | p <- tail(ps)) : "">
		| invoke(n, ps) <- coor.invokes	
	];
	writeFile(f, cleanup("#include \"<coor.name>.h\"
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h
	'****************************************/
	'#include \<stdlib.h\>
	
	'#include \"SharedState.h\"
	'<for(inv <- sort([*{n | invoke(n, _) <- coor.invokes}])) {>
		'#include \"_SM<inv>.h\"
	'<}>
	'<for(<_, inv, _> <- invokes) {>
	'static void* <inv> = NULL;
	'<}>
	'void <coor.name>_initialize(SharedState state) {
	'	<for(<n, inv, ps> <- invokes) {>
		'	 <inv> = SM_<n>_initialize(state <ps>);
	'	<}>
	'}
	'
	'void <coor.name>_performStep() {
	'	<for(<n, inv, ps> <- invokes) {>
		'	 SM_<n>_takeStep(<inv> <ps>);
	'	<}>
	'}
	'
	'int8_t <coor.name>_canSleep() {
	'	return <
			("SM_<head(invokes)[0]>_isSleepableStep(<head(invokes)[1]>)" 
				| it + "\n&& SM_<n>_isSleepableStep(<inv>)"
				| <n, inv,_> <- tail(invokes))>;
	'}
	"));
}

private str getParam(param(str t, str n)) = "<t> <n>";

private str getParams(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParam(first) | it + ", " + getParam(m) | m <- rest);
}

private default str getParams(StateMachineIdentifier smi) = "";

private str getConditionName(str con) = replaceAll(con, "?","");

private str cleanup(str inp) {
	str result = inp;
	solve(result) {
		result = visit(result) {
			case /<b:[^}]>[\n\r]+[ \t]*<a:[\n\r]+>/ => b+a
		};
	}
	return result;
}


private void writeCallbackHeader(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, cleanup("#ifndef <toUpperCase(sm.name.name)>_H
	'#define <toUpperCase(sm.name.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"SharedState.h\"
	'#include \<stdint.h\>
	'#ifdef __cplusplus
	'extern \"C\"{
	'#endif	
	
	'void <sm.name.name>_initialize(SharedState state <paramsNotFirst>);
	'
	'<for(action(ac) <- sort([ *({ *as | /[list[Action] as, _] <- sm} + {*as | /fork(_,_,as, _) <- sm})])) {>
		'void <sm.name.name>_<ac>(<params>);
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t _<sm.name.name>_con_<getConditionName(cn)>(<params>);
	'<}>
	
	'#ifdef __cplusplus
	'}
	'#endif
	'#endif
	"));
}


private void writeDefaultCallback(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, cleanup("#include \"<sm.name.name>.h\"
	'	
	'void <sm.name.name>_initialize(SharedState state <paramsNotFirst>) {
	'
	'}
	'
	'<for(action(ac) <- sort([ *({ *as | /[list[Action] as, _] <- sm} + {*as | /fork(_,_,as, _) <- sm})])) {>
		'void <sm.name.name>_<ac>(<params>) {
		'
		'}
	'<}>
	'<for(cn <- sort([ *{ con | /single(str con) <- sm}])) { >
		'uint8_t _<sm.name.name>_con_<getConditionName(cn)>(<params>) {
		'\treturn 1;
		'}
	'<}>
	"));
}

private void writeStateMachineHeader(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	writeFile(f, cleanup("#ifndef _SM<toUpperCase(sm.name.name)>_H
	'#define _SM<toUpperCase(sm.name.name)>_H
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"SharedState.h\"
	'#include \<stdint.h\>
	'#include \<stdlib.h\>
	'#ifdef __cplusplus
	'extern \"C\"{
	'#endif	
	
	'void* SM_<sm.name.name>_initialize(SharedState state <paramsNotFirst>);
	'void SM_<sm.name.name>_takeStep(void* sm <paramsNotFirst>);
	'uint8_t SM_<sm.name.name>_isSleepableStep(const void* sm);
	
	'#ifdef __cplusplus
	'}
	'#endif
	'#endif
	"));
}
private str getParamInvoke(param(str t, str n)) = "<n>";

private str getParamsInvoke(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParamInvoke(first) | it + ", " + getParamInvoke(m) | m <- rest);
}

private default str getParamsInvoke(StateMachineIdentifier smi) = "";

private str getParamTypes(param(str t, str n)) = "<t>";

private str getParamsTypes(parameterized(_, [Parameter first, list[Parameter] rest])) {
	 return (getParamTypes(first) | it + ", " + getParamTypes(m) | m <- rest);
}

private default str getParamsTypes(StateMachineIdentifier smi) = "";

private str getForkNameInvoke(action(str nm)) = "_<nm>";
private str getForkNameInvoke(name(str nm)) = "_<nm>";


private void writeStateMachineImplementation(loc f, StateMachine sm) {
	str params = getParams(sm.name);
	str paramsNotFirst = params == "" ? "" : ", " + params;
	str paramsTypes = getParamsTypes(sm.name);
	str paramsTypesNotFirst = paramsTypes == "" ? "" : ", " + paramsTypes;
	str paramsInvoke = getParamsInvoke(sm.name);
	str paramsInvokeNotFirst = paramsInvoke == "" ? "" : ", " + paramsInvoke;
	writeFile(f, cleanup("#include \"_SM<sm.name.name>.h\"
	'/***************************************
	'** This file is generated, do not edit! 
	'** You can edit SharedState.h or <sm.name.name>.cpp
	'****************************************/
	'#include \"<sm.name.name>.h\"
	'struct State;
	'typedef void (*StatePointer)(struct State* <paramsTypesNotFirst>);
	'struct State {
	'	StatePointer nextState;
	'	uint8_t sleepable;
	'};
	'<for(fork(_, fname, _, _) <- sm.definitions) {>
		'static void <getForkNameInvoke(fname)>(struct State* sm <paramsNotFirst>);
	'<}>
	'	
	'void* SM_<sm.name.name>_initialize(SharedState state <paramsNotFirst>) {
	'	<sm.name.name>_initialize(state <paramsInvokeNotFirst>);
	'#ifdef __cplusplus
	'	struct State* result = reinterpret_cast\<struct State*\>(malloc(sizeof(struct State)));
	'#else
	'	struct State* result = (struct State*)malloc(sizeof(struct State));
	'#endif
	'<if(nm := sm.startFork, fork([_*, sleepable(), _*], nm, _, _) <- sm.definitions) {>
	'	result-\>sleepable = 1;
	<} else {>
	'	result-\>sleepable = 0;
	<}>
	'	result-\>nextState = <getForkNameInvoke(sm.startFork)>;
	'	return result; 
	'}
	'
	'void SM_<sm.name.name>_takeStep(void* sm <paramsNotFirst>) {
	'#ifdef __cplusplus
	'	reinterpret_cast\<struct State*\>(sm)-\>nextState(reinterpret_cast\<struct State*\>(sm) <paramsInvokeNotFirst>);	
	'#else
	'	((struct State*)sm)-\>nextState(((struct State*)sm) <paramsInvokeNotFirst>);	
	'#endif
	'}
	'
	'uint8_t SM_<sm.name.name>_isSleepableStep(const void* sm) {
	'#ifdef __cplusplus
	'	return reinterpret_cast\<struct State*\>(sm)-\>sleepable;
	'#else
	'	return ((struct State*)sm)-\>sleepable;
	'#endif
	'}
	'<for(frk <- sm.definitions) {>
		'<generateForkBody(sm.name.name, sm.definitions, frk, paramsNotFirst, paramsInvoke)>
	'<}>
	"));
}

private str generateForkBody(str nm, list[Definition] defs, fork(fkind, fname, preActions, paths), str paramsNotFirst, str paramsInvoke) {
	return 
		"static void <getForkNameInvoke(fname)>(struct State* sm <paramsNotFirst>) {
			'	//pre actions
			'<for(action(ac) <- preActions) {>
			'	<nm>_<ac>(<paramsInvoke>);
			'<}>	
			'<for(path(con, acs) <- paths) {>	
			'	if (<translateCondition(nm, con, paramsInvoke)>) {
				'		<translateActionListToInvokesAndReturn(nm, acs, defs, paramsInvoke)>
			'	}
			'<}>
			'<if (d:defaultPath(acs) <- paths) {>
			'	<translateActionListToInvokesAndReturn(nm, acs, defs, paramsInvoke)>
			'<} else {>
			'	<translateActionListToInvokesAndReturn(nm, [action(fname.name)], defs, paramsInvoke)>
			'<}>
		'}
		";
}

private str translateCondition(str nm, single(con), str params) = "_<nm>_con_<getConditionName(con)>(<params>)";
private str translateCondition(str nm, negate(con), str params) = "!(<translateCondition(nm, con, params)>)";
private str translateCondition(str nm, and(lhs, rhs), str params) = "(<translateCondition(nm, lhs, params)> && <translateCondition(nm, rhs, params)>)";
private str translateCondition(str nm, or(lhs, rhs), str params) = "(<translateCondition(nm, lhs, params)> || <translateCondition(nm, rhs, params)>)";
private default str translateCondition(str nm, Expression e, str params) {
	throw "Unsupported expression! <e>";
}

private str translateActionListToInvokesAndReturn(str smnm, [list[Action] acs, Action lastAction], list[Definition] defs, str paramsInvoke) {
	str nm = lastAction.name;
	list[ForkType] forkTypes = [*ft | fork(ft, name(nm), _, _) <- defs];
	return 
		"<for(action(ac) <- acs) {>
			'<smnm>_<ac>(<paramsInvoke>);
		'<}>
		'<if (immediate() in forkTypes) {>
			'<getForkNameInvoke(lastAction)>(sm <paramsInvoke == "" ? "" : ", " + paramsInvoke>); // immediate fork
			'return;
		'<} else {>
			'<if(sleepable() in forkTypes) {>
				'sm-\>sleepable = 1;
			<} else {>
				'sm-\>sleepable = 0;
			<}>
			'sm-\>nextState = <getForkNameInvoke(lastAction)>;
			'return;
		'<}>
		";
}