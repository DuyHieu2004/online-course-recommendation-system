#!/bin/bash
echo "Waiting for Neo4j to start..."
until cypher-shell -u neo4j -p StrongPass@123 "RETURN 1" > /dev/null 2>&1; do
    echo "Neo4j is not ready yet... sleeping"
    sleep 5
done

echo "Neo4j is ready. Running initialization Cypher script..."
cypher-shell -u neo4j -p StrongPass@123 -f /scripts/init-neo4j.cypher

echo "Neo4j initialization completed."
