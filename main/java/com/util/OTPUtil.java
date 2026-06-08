package com.util;

import java.security.SecureRandom;

public class OTPUtil {
	public static String generateOTP() {
		SecureRandom random = new SecureRandom();
		int otp = 100000 + random.nextInt(900000); // 6-digit
		return String.valueOf(otp);
	}
}
