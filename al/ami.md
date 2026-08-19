### Fetch AMI Information
```
aws ec2 describe-images ^
  --image-ids ami-06f9e3b45a89cf4aa ^
  --query "Images[0].[ImageId,Name,CreationDate,Architecture,PlatformDetails,RootDeviceType,State]" ^
  --output table
```

### Fetch Latest 5 AMIs
```
aws ec2 describe-images ^
  --owners amazon ^
  --filters "Name=name,Values=al2023-ami-2023*" "Name=state,Values=available" ^
  --query "reverse(sort_by(Images, &CreationDate))[:5].[ImageId,Name,CreationDate]" ^
  --output table
```