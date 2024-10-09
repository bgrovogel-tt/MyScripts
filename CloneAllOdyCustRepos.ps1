# Define the hashtable with repository information
$repoInfo = @{"ca" = "git@github.com:tyler-technologies/cj-ca.git"
            #   "client_independent" = "git@github.com:tyler-technologies/cj-client_independent.git"
              "dc" = "git@github.com:tyler-technologies/cj-dc.git"
              "fl" = "git@github.com:tyler-technologies/cj-fl.git"
              "ga" = "git@github.com:tyler-technologies/cj-ga.git"
              "id" = "git@github.com:tyler-technologies/cj-id.git"
              "il" = "git@github.com:tyler-technologies/cj-il.git"
              "in" = "git@github.com:tyler-technologies/cj-in.git"
              "ks" = "git@github.com:tyler-technologies/cj-ks.git"
              "la" = "git@github.com:tyler-technologies/cj-la.git"
              "md" = "git@github.com:tyler-technologies/cj-md.git"
              "me" = "git@github.com:tyler-technologies/cj-me.git"
              "mi" = "git@github.com:tyler-technologies/cj-mi.git"
              "mn" = "git@github.com:tyler-technologies/cj-mn.git"
              "nc" = "git@github.com:tyler-technologies/cj-nc.git"
              "nd" = "git@github.com:tyler-technologies/cj-nd.git"
              "nh" = "git@github.com:tyler-technologies/cj-nh.git"
              "nm" = "git@github.com:tyler-technologies/cj-nm.git"
              "northern_territory_australia" = "git@github.com:tyler-technologies/cj-northern_territory_australia.git"
              "nv" = "git@github.com:tyler-technologies/cj-nv.git"
              "oh" = "git@github.com:tyler-technologies/cj-oh.git"
              "or" = "git@github.com:tyler-technologies/cj-or.git"
              "pa" = "git@github.com:tyler-technologies/cj-pa.git"
              "ri" = "git@github.com:tyler-technologies/cj-ri.git"
              "sd" = "git@github.com:tyler-technologies/cj-sd.git"
              "tn" = "git@github.com:tyler-technologies/cj-tn.git"
              "tx" = "git@github.com:tyler-technologies/cj-tx.git"
              "vt" = "git@github.com:tyler-technologies/cj-vt.git"
              "wa" = "git@github.com:tyler-technologies/cj-wa.git"}

# Function to clone a repository
function Clone-Repo {
    param (
        [string]$repoUrl,
        [string]$targetPath
    )
    git clone $repoUrl $targetPath
}

# Path where repositories will be cloned
$targetBasePath = "C:\TylerDev\mainline\repos\custext"

# Iterate over the hashtable and clone each repository
foreach ($key in $repoInfo.Keys) {
    $repoUrl = $repoInfo[$key]
    $targetPath = Join-Path -Path $targetBasePath -ChildPath $key
    Clone-Repo -repoUrl $repoUrl -targetPath $targetPath
}