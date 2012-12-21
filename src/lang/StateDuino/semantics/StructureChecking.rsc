module lang::StateDuino::semantics::StructureChecking

import Map;
import List;
import Set;
import Message;
import Relation;
import analysis::graphs::Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;


public set[Message] structureCheck(StateMachine sm) {
	set[Message] result = checkForAlreadyDefinedNames(sm);
	result += checkForDefineLoops(sm);
	result += immediateActionsNeverFork(sm);
	return result;
}


private set[Message] checkForAlreadyDefinedNames(StateMachine sm) {
	set[Message] result = {};
	set[Name] alreadyDefined = {};
	for (d <- sm.definitions, d.name?) {
		if (d.name in alreadyDefined) {
			result += {error("<d.name.name> is already defined", d.name@location)};
		}
		alreadyDefined += {d.name};
	}
	return result;
}

private str getName(action(name(nm))) = nm;
private str getName(definition(d)) = "_fork";
		

private set[Message] checkForDefineLoops(StateMachine sm) {
	set[Message] result = {};
	rel[str, str] chainPaths = { *{<st.name, ac> | /action(name(str ac)) <- acs} | chain(st, list[Action] acs) <- sm.definitions};
	chainPaths = chainPaths+;
	
	set[str] invalidChains = {};
	solve(invalidChains) {
		for (chain(n:name(str st),_ ) <- sm.definitions, <st, st> in chainPaths) {
			invalidChains += {st};
			result += error("<st> has a definition loop.", n@location);
		}
		for (chain(n:name(str st),_ ) <- sm.definitions, (chainPaths[st] & invalidChains) > {}) {
			invalidChains += {st};
			result += error("<st> calls a chain which has a definition loop.", n@location);
		}	
	}
	return result;
}

private str getName(Definition def) = (def.name?) ? def.name.name : "nameless";
private str getName(action(name(nm))) = nm;
private str getName(definition(def)) = getName(def);

private set[Message] immediateActionsNeverFork(StateMachine sm) {
	set[str] forksKnown = {nm | fork(_, name(nm), _, _) <- sm.definitions};
	// chains ending in forks also count (either defined inline or referenced)
	forksKnown += { c | chain(name(c), [_*, lastAction]) <- sm.definitions, definition(_) := lastAction || (lastAction.name? && lastAction.name.name in forksKnown) };
	forksKnown += { "self" };
	
	set[Message] checkPreActions(Definition def, set[str] knownForks) {
		set[Message] result = {};
		if ([_*, lastAction] := def.preActions) {
			if (action(name(an)) := lastAction, an in knownForks) {
				result += preActionsMessage(def, lastAction); 	
			}	
			else if (definition(d) := lastAction) {
				result += preActionsMessage(def, lastAction); 	
			}
		}
		for (p <- def.paths, [_*, definition(d)] := p.actions) {
			result += checkPreActions(d, knownForks + getName(def));
		}
		return result;	
	}
	
	set[Message] preActionsMessage(Definition def, Action ac) {
		return {error("Always executing actions of <getName(def)> cannot end in a fork (<getName(ac)>)", ac@location) };		
	}
	return {*checkPreActions(d, forksKnown) | d <- sm.definitions, chain(_,_) !:= d};
}