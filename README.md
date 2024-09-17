## Tailscale Take Home Test



### Diagram

![Diagram](https://github.com/mon1torGuy/tailscale-tht/blob/main/diagram.png?raw=true)


### Usage

- Clone the repository
```
git clone https://github.com/mon1torGuy/tailscale-tht.git

```

- Replace the variable placeholders in the file `variable.tf`

`project_id`: "# Replace with your GCP project ID"

`tailscale_tailnet`: # Replace with your Tailscale Tailnet name"

`tailscale_api_key`: "# Replace with your Tailscale API Key"

- Install Google Cloud CLI `gcloud`  login with a user that has permission over the project ID specified.

- Install terraform
> [!NOTE]
> On Tailscale is needed to change the ACL, to allow Auto Approve from the router. So you don't need to manually approve all routes everytime a router is created. (Pending to add this step to the Terraform automation)


Tag should be called `tag:router`, add it to the tagOwnsers and add the network `10.0.1.0/24` to the autoApprovers reference the tag. something similar like this.

```
	"tagOwners": {
		"tag:router": [],
	},
	"autoApprovers": {
		"routes": {
			"10.0.1.0/24": ["pcaminog@gamil.com", "tag:router"],
		},
	},
```

Once all the above is in place, you are all set.

```
terraform init
terraform apply  -auto-approve
```

The deployments should create the following elements:

- 2 VM Debian micro
- 1 VPC
- 1 Subnet
- 3 Firewall Rules
- 1 Auth Key in Tailscale
  
Once the terraform is complete.

From your computer with Tailscale installed and authenticated on the same account you should be able to:

```
ssh tailscale-device
ssh tailscale-router
ssh 10.0.1.2 # router
ssh 10.0.1.3 # device
```