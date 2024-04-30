// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/

// Task 1
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello world");
  createWorkspace(OrgName);
  .print("Organization initialized: ", OrgName);
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId)[wid(WorkspaceId)];
  focus(OrgBoardArtId)[wid(WorkspaceId)];

  createGroup(GroupName, GroupName, G)[artifact_id(OrgBoardArtId)];
  focus(G)[wid(WorkspaceId)];

  createScheme(SchemeName, SchemeName, SchemeArtId)[artifact_id(OrgBoardArtId)];
  focus(SchemeArtId)[wid(WorkspaceId)];

  .broadcast(tell, org_created(OrgName));

  !inspect(G)[wid(WorkspaceId)];
  !inspect(SchemeArtId)[wid(WorkspaceId)];
  ?formationStatus(ok)[artifact_id(G)].


/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/

@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  //.wait({+formationStatus(ok)[artifact_id(G)]}).
  //addSchemeWhenFormationIsOk(GroupName). 

  .wait(15000);
  !active_group_formation_plan(GroupName);
  .wait({+formationStatus(ok)[artifact_id(G)]}).


@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] & scheme(SchemeName,SchemeType,SchemeArtId) <-
  .print(GroupName, " = formation status OK");
  addScheme(SchemeName)[artifact_id(G)];
  focus(SchemeArtId).






/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).



// Periodic plan to check group formation status and promote role adoption if needed
@active_group_formation_plan
+!active_group_formation_plan(GroupName) : formationStatus(nok) & group(GroupName, GroupType, G) & org_name(OrgName) <-
  if (not has_enough_players_for(temperature_reader, GroupName)) {
    .print("Not enough players for role: temperature_reader in ", GroupName);
    .broadcast(tell, ask_fulfill_role(temperature_reader, GroupName, OrgName));
  }
  if (not has_enough_players_for(temperature_manifestor, GroupName)) {
    .broadcast(tell, ask_fulfill_role(temperature_manifestor, GroupName, OrgName));
    .print("Not enough players for role: temperature_manifestor in ", GroupName);
  }
  .wait(15000);
  if (not (has_enough_players_for(temperature_reader, GroupName) & has_enough_players_for(temperature_manifestor, GroupName))) {
    !active_group_formation_plan(GroupName); // Note: GroupName is used to trigger the next iteration
  }.

/*
  ?formationStatus(ok)[artifact_id(G)];
    if (not .check_group_well_formed(G)) {
        !active_group_formation_plan(GroupName);  // Repeat checking until the group is well-formed
    } else {
        .print(GroupName, " is now well-formed.");
        .take_responsibility_for_monitoring_scheme(G); // Custom action to handle post-formation tasks
    }.
*/





/*
Not needed: Handling Role Adoption and Monitoring Helper Functions below

+!adopt_role_and_commit_to_mission[artifact_id(GroupBoard)] <-
    .adoptRole("temperature_reader", GroupBoard);
    .commitMission("temperature_reading_mission", GroupBoard).

+!adopt_role_and_commit_to_mission[artifact_id(GroupBoard)] <-
    .adoptRole("temperature_manifestor", GroupBoard);
    .commitMission("temperature_manifesting_mission", GroupBoard).

+formationStatus(ok)[artifact_id(G)] : group(GroupName, _, G)[artifact_id(OrgName)] <-
    .print("Group ", GroupName, " is well-formed.");
    .adopt_role_and_commit_to_mission(GroupBoard).

+missionAccomplished(MissionId)[artifact_id(G)] : scheme(SchemeName, _, G)[artifact_id(OrgName)] <-
    .print("Mission ", MissionId, " is accomplished.").

+!inspect(OrganizationalArtifactId) : true <-
    debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 
*/


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }