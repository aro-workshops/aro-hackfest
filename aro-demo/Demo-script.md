Demo Script
===========

Deploy demo
-----------

* Show app working
* Show ARO resources
* Show Azure resources
* Generate traffic
* Show cosmos DB data explorer

Show App insights
-----------------

* Default charts
* Application map
* Filter by Web
* Select data-api calls
* Investigate performance (last 30 mins), drill into samples, GET /status, User flows, Trend
* Investigate failures, See exceptions

Show Azure monitor
------------------

* Containers -> cluster -> Containers -> data-api -> View container logs
* Remove time range in query (set to 30 mins) -> See LogEntry
* **Kusto query 1** – Percentage of saves by resource piechart

    ```kql
    ContainerLog
    | where LogEntry contains "POST /save"
    ...
    on ContainerID
    | parse LogEntry with * "POST /save/" resourceName "/" *
    | summarize count() by resourceName
    | render piechart
    ```

* **Kusto query 2** – Resource saves timechart

    ```kql
    ContainerLog
    | where LogEntry contains "POST /save"
    ...
    on ContainerID
    | summarize Saves=count() by bin(TimeGenerated, 1m)
    | render timechart
    ```

* **Kusto query 3** – GET vs POST columchart

    ```kql
    ContainerLog
    | where LogEntry contains "[0m"
    ...
    on ContainerID
    | parse LogEntry with * "[0m" method " /" verb "/" resourceName "/" *
    | summarize count=count() by method, bin(TimeGenerated, 1m)
    | render columnchart with (kind = unstacked)
    ```
