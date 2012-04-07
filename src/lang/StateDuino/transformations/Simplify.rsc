module lang::StateDuino::transformations::Simplify

import List;
import Map;
import IO;
import Relation;
import Set;
import lang::StateDuino::ast::Main;

public StateMachine simplify(StateMachine complex) {
	StateMachine result = complex;
	result = removeUnnamedForks(result);
	result = removeSelfReferences(result);
	result = inlineChains(result);
	result = unnestForks(result);
	return result;
}
private StateMachine removeUnnamedForks(StateMachine sm) {
	int newNameCounter = 0;
	return visit(sm) {
		case f:namelessFork(types, pre, paths) : {
			Name newName = name("_nameless<newNameCounter>")[@location = f@location];
			newNameCounter += 1;
			insert fork(types, newName , pre, paths)[@location = f@location];
		}
	};
}

private StateMachine removeSelfReferences(StateMachine sm) {
	list[Definition] newDefinitions = [];
	for (d <- sm.definitions) {
		switch(d) {
			case chain(_,_) : newDefinitions += [d];
			case fork(_,_,_,_) : newDefinitions += [removeSelfReferences(d)];
			default : throw "Case <d> forgotten";
		}	
	}
	return sm[definitions = newDefinitions];
}

private Definition removeSelfReferences(f:fork(_,nm, _, paths)) {
	list[ConditionalPath] newPaths = [];
	for (p <- paths) {
		newPaths += [p[actions=removeSelfReferences(p.actions, nm.name)]];
	}
	return f[paths = newPaths];
}
private list[Action] removeSelfReferences(list[Action] acs, str nm) {
	list[Action] newActions = [];
	for (a <- acs) {
		switch(a) {
			case action("self") : newActions += [a[name=nm]];
			case action(_) : newActions += [a];
			case definition(d) : newActions += [a[definition= removeSelfReferences(d)]];
			default : throw "Case <a> forgotten";
		}	
	}
	return newActions;
}

private default Definition removeSelfReferences(Definition d) {
	throw "Not supported definition";
}

private StateMachine inlineChains(StateMachine complex) {
	map[str, list[Action]] chainActions = ( m : p | chain(name(m), p) <- complex.definitions);
	solve(chainActions) {
		for (cn <- chainActions) {
			list[Action] acs = chainActions[cn];
			if (chainActions[last(acs).name]?) {
				// nested chain call;
				chainActions[cn] = prefix(acs) + chainActions[last(acs).name];
			}
		}
	}
	list[Action] replaceActions(list[Action] acts, set[str] nestedForkNames) {
		list[Action] result = [];
		for (a <- acts) {
			switch(a) {
				case action(nm): 
					if (!(nm in nestedForkNames) && chainActions[nm]?) {
						result += chainActions[nm];	
					}	
					else {
						result += [a];	
					}
				case d:definition(f) : {
					result += [d[definition = replaceActions(f, nestedForkNames + (f.name? ? {f.name.name} : {}))]];	
				}
			}
		}
		return result;
	};
	
	Definition replaceActions(Definition def, set[str] nestedForkNames) {
		list[ConditionalPath] newPaths = [];
		for (p <- def.paths) {
			newPaths += [p[actions = replaceActions(p.actions, nestedForkNames)]];
		}
		newPreActions = replaceActions(def.preActions, nestedForkNames);
		return def[paths= newPaths][preActions = newPreActions];
	};	
	// check forks inside chains
	for (cn <- chainActions) {
		chainActions[cn] = replaceActions(chainActions[cn], {cn});	
	}
	list[Definition] newDefinitions = [replaceActions(f, {}) | f:fork(_,_,_,_) <- complex.definitions];
	return complex[definitions = newDefinitions];
}

// assumes no chains, no definition loops, no nameless forks
private StateMachine unnestForks(StateMachine sm) {
	map[str, str] namesSeen = (nm:nm | fork(_, name(nm), _, _) <- sm.definitions);
	list[Definition] newDefinitions = [];
	tuple[Definition, map[str, str]] renameAndUnnest(Definition f, map[str, str] alreadyRenamed) {
		list[ConditionalPath] newPaths = [];
		for (p <- f.paths) {
			if (definition(fn:fork(_, name(nm), _, _)) := last(p.actions)) {
				str newName = nm;
				while (alreadyRenamed[newName]?) {
					newName = "_" + newName;
				}
				<fn, newNames> = renameAndUnnest(fn, alreadyRenamed + (nm : newName));		
				alreadyRenamed += newNames;
				alreadyRenamed[newName] = newName;
				newDefinitions += [fn[name = fn.name[name = newName]]];
				newPaths += [p[actions = prefix(p.actions) + [action(newName)[@location = f@location]]]];
			} 
			else {
				if (alreadyRenamed[last(p.actions).name]?) {
					Action newLast = last(p.actions)[name = alreadyRenamed[last(p.actions).name]];
					p = p[actions = prefix(p.actions) + [newLast]];
				}
				newPaths += [p];	
			}
		}
		return <f[paths = newPaths], alreadyRenamed>;
	}
	list[Definition] rewroteDefinitions = [];
	for (f <- sm.definitions) {
		<f, newNames> = renameAndUnnest(f, namesSeen);		
		rewroteDefinitions += [f];
		namesSeen += newNames;	
	}
	return sm[definitions = rewroteDefinitions + newDefinitions];
}