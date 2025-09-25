# Arc inventory with Azure Resource Graph

## Quick list
```bash
az extension add --name resource-graph --upgrade
az graph query -q "resources | where type =~ 'microsoft.hybridcompute/machines' | project name, resourceGroup, subscriptionId, location, id" --first 1000 -o table
```

## Common filters
- **By subscription**
  ```bash
  SUB="<SUB_ID>"
  az graph query -q "resources
    | where type =~ 'microsoft.hybridcompute/machines' and subscriptionId == '${SUB}'
    | project name, resourceGroup, location, id" --first 1000 -o table
  ```

- **Windows only** (example heuristic; adjust to your tags/fields)
  ```bash
  az graph query -q "resources
    | where type =~ 'microsoft.hybridcompute/machines' and tolower(osName) has 'windows'
    | project name, resourceGroup, location, id" --first 1000 -o table
  ```

- **Export to CSV**
  ```bash
  az graph query -q "resources
    | where type =~ 'microsoft.hybridcompute/machines'
    | project name, resourceGroup, location, id" --first 1000 -o tsv       | awk 'BEGIN{FS="\t"; OFS=","} NR==1{print "name","resourceGroup","location","id"} NR>1{print $1,$2,$3,$4}'       > arc-machines.csv
  ```
