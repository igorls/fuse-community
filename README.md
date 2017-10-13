# fuse-cryptography
Uno implementation for cryptographic hashing functions


## Contents

Currently contains:

1. Sha1, HmacSha1, and OneTimePassword from http://www.codeproject.com/Articles/592275/OTP-One-Time-Password-Demystified
2. SHA256 from http://hashlib.codeplex.com/

3. SHA512 from mono

In addition, it contains sample code for using the libraries.

## Usage

A Javascript API is available, and the usage of it is shown in the ExampleUsage.ux file.  To link your fuse project to the fuse-cryptography project make sure that the fuse-cryptography.unoproj is included in your unoproj file like the following:

```
  "Projects": ["../fuse-cryptography/fuse-cryptography.unoproj"],
```

And in your Javascript file:
```
			var Crypto = require("Cryptography");
```

You will likely want to set a salt and pepper for the App:
```
			Crypto.setAppSalt("Lowry's");
			Crypto.setAppPepper("Seasoned");
```

To get the SHA256 hash of a password (optional salt):
```
			var hash = Crypto.hashPassword(pwd,salt);
```

To get the SHA512 hash of a password (optional salt):
```
			var hash = Crypto.hashPassword512(pwd,salt);
```

To get a one time password at a particular instance (ie the first, or the fifteenth)
```
			var firstOTP= Crypto.getOTP(1, pwd); 
			var fifteenthOTP = Crypto.getOTP(15,pwd);
```
