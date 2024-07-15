Import-Module Microsoft.Graph.Identity.SignIns

#Update the Named Location Policy, prividing a JSON formatted file of the parameters you want to update
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId "07a1f48d-0cbb-4c2c-8ea2-1ea00e3eb3b6" -BodyParameter $namedLocationJson