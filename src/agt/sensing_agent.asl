// sensing agent


/* Initial beliefs and rules */

/* Check if role R can achieve a goal G through a mission. */
+!check_role_goal(R, G) : role_mission(R, _, M) & mission_goal(M, G) <- .print("Role ", R, " has goal ", G, " through mission ", M).

/* Check if it is possible to achieve goal G (there are relevant plans to achieve G). */
+!check_can_achieve(G) : .relevant_plans(G, LP) & LP \== [] <- .print("Goal ", G, " is achievable with plans.", LP).

/* Determine if all goals of a role R are achievable. */
+!check_i_have_plans_for(R) : not (check_role_goal(R, G) & not check_can_achieve(G)).



/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

// Task 2
// Reacting to the creation of new organization workspaces
@org_created_plan
+org_created(OrgName) : org_name(OrgName) <-
	createWorkspace(OrgName);
	makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId)[wid(WorkspaceId)];
	focus(OrgBoardArtId)[wid(WorkspaceId)];
	.broadcast(tell, org_created(OrgName));
	.print("Workspace and OrgBoard artifact created and focused: ", OrgName).

// Listening to the observable properties of the organization
+group(GroupId, GroupType, G) : group_name(GroupName) & GroupId == GroupName <-
	focus(G)[wid(WorkspaceId)];
	!reasoning_for_role_adoption(temperature_reader);
	!reasoning_for_role_adoption(temperature_manifestor).

// Listening to the observable properties of the organization
+scheme(SchemeId, SchemeType, SchemeArtId) : sch_name(SchemeName) & SchemeId == SchemeName <-
	focus(SchemeArtId)[wid(WorkspaceId)].

//  Reasoning on the organization and adoption of relevant roles
@reasoning_for_role_adoption_plan
+!reasoning_for_role_adoption(Role) : i_have_plan_for_role(Role) <-
	.print("I have a plan for the role: ", Role);
	adoptRole(Role, G)[artifact_id(OrgBoardArtId)]. // Assuming OrgBoardArtId holds reference to Group Artifacts as context

+!reasoning_for_role_adoption(Role) : true <-
	.print("No plan for the role: ", Role).


/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }