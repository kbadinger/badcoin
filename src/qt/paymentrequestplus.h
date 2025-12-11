// Copyright (c) 2011-2017 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_QT_PAYMENTREQUESTPLUS_H
#define BITCOIN_QT_PAYMENTREQUESTPLUS_H

#if defined(HAVE_CONFIG_H)
#include <config/bitcoin-config.h>
#endif

#include <QByteArray>
#include <QList>
#include <QString>

static const bool DEFAULT_SELFSIGNED_ROOTCERTS = false;

#if defined(ENABLE_BIP70)

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#include <qt/paymentrequest.pb.h>
#pragma GCC diagnostic pop

#include <base58.h>

#include <openssl/x509.h>

//
// Wraps dumb protocol buffer paymentRequest
// with extra methods
//

class PaymentRequestPlus
{
public:
    PaymentRequestPlus() { }

    bool parse(const QByteArray& data);
    bool SerializeToString(std::string* output) const;

    bool IsInitialized() const;
    // Returns true if merchant's identity is authenticated, and
    // returns human-readable merchant identity in merchant
    bool getMerchant(X509_STORE* certStore, QString& merchant) const;

    // Returns list of outputs, amount
    QList<std::pair<CScript,CAmount> > getPayTo() const;

    const payments::PaymentDetails& getDetails() const { return details; }

private:
    payments::PaymentRequest paymentRequest;
    payments::PaymentDetails details;
};

#else // ENABLE_BIP70 not defined - stub class

//
// Stub class when BIP70 is disabled
//
class PaymentRequestPlus
{
public:
    PaymentRequestPlus() { }

    bool parse(const QByteArray& data) { return false; }
    bool SerializeToString(std::string* output) const { return false; }
    bool IsInitialized() const { return false; }
};

#endif // ENABLE_BIP70

#endif // BITCOIN_QT_PAYMENTREQUESTPLUS_H
