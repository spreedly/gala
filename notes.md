## Generating the Apple Root Certificate

In order to get the certificate into a usable format, the following java code was used.
```
  InputStream inputStream = null;
  X509Certificate appleRootCertificate = null;

  try {
    InputStream in = new FileInputStream(new File("/Users/mrezentes/Documents/workspace/AndroidPay/src/AppleRootCA-G3.cer"));
    CertificateFactory certificateFactory = CertificateFactory.getInstance(X_509);
    appleRootCertificate = (X509Certificate) certificateFactory.generateCertificate(in);
    PEMWriter pw = new PEMWriter(new PrintWriter(System.out));
    pw.writeObject(appleRootCertificate);
    pw.flush();
    pw.close();
  }

```