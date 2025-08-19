# --- Bundle Commands ---
validate-bundle:
	@echo "Validating Databricks bundle..."
	databricks bundle validate

generate-dashboard:
	@echo "Generating dashboard JSON from workspace..."
	databricks bundle generate dashboard --existing-path "/Workspace/Users/ahmedrufai.otuoze@data2bots.com/.bundle/ad_monitor/custom/resources/ad_serving.lvdash.json" --dashboard-dir "src/dashboards/" --force

validate: validate-bundle generate-dashboard
	@echo "✅ Validation and dashboard generation complete."

deploy:
	@echo "Deploying Databricks bundle to dev target..."
	databricks bundle deploy -t custom

destroy:
	@echo "Destroying all resources for dev target..."
	databricks bundle destroy -t custom



