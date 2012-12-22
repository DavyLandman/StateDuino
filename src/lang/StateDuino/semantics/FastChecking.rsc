module lang::StateDuino::semantics::FastChecking

import Map;
import List;
import Set;
import Message;
import Relation;
import analysis::graphs::Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;

public set[Message] fastCheck(StateMachine sm) {
	set[Message] result ={};
	visit(sm) {
		case p:param(name(str name), _) : 
			if (! (name in validParameterTypes)) {
				result += {error("Type <name> is not supported",p@location)};
			}
		case [_*, definition(def), list[Action] followingDefinition]:
			if (c:chain(_,_) := def) {
				result += {error("You cannot nest a chain (<c.name.name>).", c.name@location)};
			} 
			else if (size(followingDefinition) > 0) {
				result += {error("There should be no more actions after a call to a fork (<def.name? ? def.name.name : "nameless">).", def.name? ? def.name@location : def@location)};
			}
		case f:fork(_, _, _, []) : result += {emptyBodyMessage(f)};
		case f:namelessFork(_, _, []) : result += {emptyBodyMessage(f)};
		case c:chain(_, []) : result += {emptyBodyMessage(c)};
		case p:path(_, []) : result += {emptyBodyMessage(p)};
		case p:defaultPath(_, []) : result += {emptyBodyMessage(p)};
	};
	for (f:namelessFork(_,_,_) <- sm.definitions) {
		result += {error("A nameless toplevel fork can never be called.", f@location)};	
	}
	return result;
}
private Message emptyBodyMessage(Definition def) {
	if (chain(_,_) := def) {
		return emptyBodyMessage(def.name.name, "action", def.name@location);
	}
	else if (namelessFork(_,_,_) := def) {
		return emptyBodyMessage("nameless", "condition", def@location);
	}
	return emptyBodyMessage(def.name.name, "condition", def.name@location);
}
private Message emptyBodyMessage(ConditionalPath pth) 
	= emptyBodyMessage("condition", "action", pth@location);
	
private Message emptyBodyMessage(str name, str missing, loc l) = error("You must define at least one <missing> for <name>.", l);