#Script creats semicolon list of users to use it in Service Store lists
$users = @"
$[users]
"@

$users = $users.Split("`n")

$UsersCommaSepar=""

foreach ($user in $users)
    {
        $UsersCommaSepar += $user
        $UsersCommaSepar +=";"
    }

$UsersCommaSepar
