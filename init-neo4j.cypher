// 1. Create constraints
CREATE CONSTRAINT course_id IF NOT EXISTS FOR (c:Course) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE;

// 2. Import Courses
LOAD CSV WITH HEADERS FROM 'file:///Online_Courses_Full.csv' AS row
WITH row WHERE row.CourseID IS NOT NULL AND row.Category IS NOT NULL AND row.Instructors IS NOT NULL
WITH row.Title AS courseTitle, collect(row)[0] AS row
MERGE (c:Course {id: toInteger(row.CourseID)})
SET c.title = courseTitle, 
    c.url = row.URL, 
    c.rating = toFloat(row.Rating);

LOAD CSV WITH HEADERS FROM 'file:///Online_Courses_Full.csv' AS row
MATCH (c:Course {id: toInteger(row.CourseID)})
MERGE (cat:Category {name: row.Category})
MERGE (c)-[:BELONGS_TO]->(cat);

LOAD CSV WITH HEADERS FROM 'file:///Online_Courses_Full.csv' AS row
MATCH (c:Course {id: toInteger(row.CourseID)})
UNWIND split(row.Instructors, ',') AS inst
WITH c, trim(inst) AS instructorName
WHERE instructorName <> ''
MERGE (i:Instructor {name: instructorName})
MERGE (i)-[:CONDUCTS]->(c);

LOAD CSV WITH HEADERS FROM 'file:///Online_Courses_Full.csv' AS row
MATCH (c:Course {id: toInteger(row.CourseID)})
WHERE row.Skills IS NOT NULL
UNWIND split(row.Skills, ',') AS skill
WITH c, trim(skill) AS topicName
WHERE topicName <> ''
MERGE (t:Topic {name: topicName})
MERGE (c)-[:HAS_TOPIC]->(t);

// 3. Import User Interactions
LOAD CSV WITH HEADERS FROM 'file:///mock_user_interactions.csv' AS row
WITH row WHERE row.UserID IS NOT NULL AND row.CourseID IS NOT NULL AND row.Rating IS NOT NULL
WITH row.UserID AS uID, row.CourseID AS cID, collect(row)[-1] AS row
MERGE (u:User {id: toInteger(uID)})
WITH u, row, cID
MATCH (c:Course {id: toInteger(cID)})
MERGE (u)-[r:RATED]->(c)
SET r.rating = toInteger(row.Rating);

// 4. Content-based cleanup and projection
MATCH ()-[r:CONTENT_SIMILAR]-() DELETE r;
CALL gds.graph.drop('contentGraph', false);
CALL gds.graph.project('contentGraph', ['Course','Topic'], ['HAS_TOPIC']);
CALL gds.nodeSimilarity.write('contentGraph', {
    nodeLabels:['Course','Topic'],
    writeRelationshipType: 'CONTENT_SIMILAR',
    writeProperty: 'score',
    similarityCutoff: 0.5
});
